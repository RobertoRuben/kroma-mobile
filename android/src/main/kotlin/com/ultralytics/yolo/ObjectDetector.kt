// Ultralytics 🚀 AGPL-3.0 License - https://ultralytics.com/license

package com.ultralytics.yolo
import android.content.Context
import android.graphics.Bitmap
import android.graphics.RectF
import android.util.Log
import org.tensorflow.lite.DataType
import org.tensorflow.lite.Interpreter
import org.tensorflow.lite.gpu.GpuDelegate
import org.tensorflow.lite.gpu.CompatibilityList
import org.tensorflow.lite.nnapi.NnApiDelegate
import org.tensorflow.lite.support.common.FileUtil
import org.tensorflow.lite.support.common.ops.CastOp
import org.tensorflow.lite.support.common.ops.NormalizeOp
import org.tensorflow.lite.support.image.ops.Rot90Op
import org.tensorflow.lite.support.image.ImageProcessor
import org.tensorflow.lite.support.image.TensorImage
import org.tensorflow.lite.support.image.ops.ResizeOp
import org.tensorflow.lite.support.metadata.MetadataExtractor
import org.tensorflow.lite.support.metadata.schema.ModelMetadata
import org.yaml.snakeyaml.Yaml
import java.nio.ByteBuffer
import java.nio.ByteOrder
import android.content.res.AssetManager
import android.os.Build

import org.json.JSONObject

import java.io.ByteArrayInputStream
import java.io.File
import java.nio.MappedByteBuffer
import java.nio.charset.StandardCharsets

import java.util.zip.ZipEntry
import java.util.zip.ZipInputStream
/**
 * High-performance ObjectDetector that assumes no 90-degree rotation is needed
 * - Performs "resize -> getPixels -> ByteBuffer" in one pass, minimizing Canvas drawing
 * - Reuses Bitmap / ByteBuffer to reduce allocations
 * - Reuses inference output arrays
 */
class ObjectDetector(
    private val context: Context,
    private val modelPath: String,
    override var labels: List<String>,
    private val useGpu: Boolean = true,
    private var numItemsThreshold: Int = 30,
    private val customOptions: Interpreter.Options? = null
) : BasePredictor() {
    // Inference output dimensions
    private var out1 = 0
    private var out2 = 0
    // Three image processors: camera portrait, camera landscape, and single images
    private lateinit var imageProcessorCameraPortrait: ImageProcessor
    private lateinit var imageProcessorCameraPortraitFront: ImageProcessor
    private lateinit var imageProcessorCameraLandscape: ImageProcessor
    private lateinit var imageProcessorSingleImage: ImageProcessor


//    companion object {
//
//    }
    // Reuse inference output array ([1][out1][out2])
    private lateinit var rawOutput: Array<Array<FloatArray>>
    // Transposed array for post-processing
    private lateinit var predictions: Array<FloatArray>
    
    // Reusable TensorImage to avoid allocations in hot path
    private lateinit var reusableTensorImage: TensorImage

    // ======== Workspace for fast preprocessing ========
    // (1) Temporary scaled Bitmap matching model input size
    //     No 90-degree rotation needed, so simply cache createScaledBitmap() equivalent
    private lateinit var scaledBitmap: Bitmap

    // (2) Array to temporarily store pixels (inWidth*inHeight)
    private lateinit var intValues: IntArray

    // (3) ByteBuffer for TFLite input (1 * height * width * 3 * 4 bytes)
    private lateinit var inputBuffer: ByteBuffer
    
    // Track active delegates for cleanup
    private var gpuDelegate: GpuDelegate? = null
    private var nnApiDelegate: NnApiDelegate? = null
    
    // Track which acceleration is being used
    private var accelerationType: String = "CPU"

    // Detect if model is quantized (int8) based on model name
    private fun isQuantizedModel(modelPath: String): Boolean {
        val lowerPath = modelPath.lowercase()
        return lowerPath.contains("int8") || lowerPath.contains("quant")
    }
    
    // Detect if model is float16 based on model name
    private fun isFloat16Model(modelPath: String): Boolean {
        val lowerPath = modelPath.lowercase()
        return lowerPath.contains("float16") || lowerPath.contains("fp16")
    }

    // Options for TensorFlow Lite Interpreter - ultra optimized for each model type
    private fun createInterpreterOptions(modelPath: String): Interpreter.Options {
        return (customOptions ?: Interpreter.Options()).apply {
            val numCores = Runtime.getRuntime().availableProcessors()
            val isQuantized = isQuantizedModel(modelPath)
            val isFloat16 = isFloat16Model(modelPath)
            
            // When using GPU/NNAPI delegates, fewer CPU threads are better
            // The delegate handles parallelism internally
            val optimalThreads = if (useGpu) {
                // Minimal CPU threads when GPU/NNAPI handles compute
                2.coerceAtMost(numCores)
            } else {
                // More threads for pure CPU execution
                numCores.coerceIn(4, 8)
            }
            setNumThreads(optimalThreads)
            
            // Try to enable XNNPack for faster CPU execution (available in TFLite 2.3+)
            try {
                setUseXNNPACK(true)
            } catch (e: Exception) {
                Log.d(TAG, "XNNPack not available: ${e.message}")
            }
            
            if (!useGpu) {
                accelerationType = "CPU (XNNPack, $optimalThreads threads)"
                Log.d(TAG, "Using $accelerationType")
                return@apply
            }
            
            when {
                isQuantized -> configureForQuantized()
                isFloat16 -> configureForFloat16()
                else -> configureForFloat32()
            }
        }
    }
    
    // Configure NNAPI for INT8 quantized models - ULTRA OPTIMIZED for 40+ FPS
    private fun Interpreter.Options.configureForQuantized() {
        val numCores = Runtime.getRuntime().availableProcessors()
        
        // First try NNAPI (best for INT8 on supported devices)
        try {
            val nnApiOptions = NnApiDelegate.Options().apply {
                // INT8 models should stay in INT8, not convert to FP16
                setAllowFp16(false)
                // Never fallback to CPU - we want NPU only
                setUseNnapiCpu(false)
                // FAST_SINGLE_ANSWER gives lowest latency per inference
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                    setExecutionPreference(NnApiDelegate.Options.EXECUTION_PREFERENCE_FAST_SINGLE_ANSWER)
                }
            }
            nnApiDelegate = NnApiDelegate(nnApiOptions)
            addDelegate(nnApiDelegate)
            // With NNAPI, use minimal CPU threads since NPU handles compute
            setNumThreads(2)
            accelerationType = "NNAPI (INT8 NPU)"
            Log.d(TAG, "✅ NNAPI delegate configured for INT8 with FAST_SINGLE_ANSWER")
        } catch (e: Exception) {
            Log.w(TAG, "NNAPI failed: ${e.message}, using XNNPack for INT8...")
            // Fallback to XNNPack with ALL cores for maximum INT8 performance
            setNumThreads(numCores)
            try {
                setUseXNNPACK(true)
                accelerationType = "XNNPack (INT8, $numCores threads)"
                Log.d(TAG, "✅ XNNPack configured for INT8 with $numCores threads")
            } catch (e2: Exception) {
                accelerationType = "CPU (INT8, $numCores threads)"
                Log.w(TAG, "XNNPack also failed: ${e2.message}, using basic CPU")
            }
        }
    }
    
    // Configure for Float16 models - XNNPack primary (YOLO detector has too many
    // GPU-unsupported ops; GPU only handles ~14/993 nodes, causing fragmented partitions
    // and corrupted post-processing output. Classifier uses GPU successfully.)
    private fun Interpreter.Options.configureForFloat16() {
        val numCores = Runtime.getRuntime().availableProcessors()
        setNumThreads(numCores)
        try {
            setUseXNNPACK(true)
            accelerationType = "XNNPack (FP16, $numCores threads)"
            Log.d(TAG, "✅ XNNPack configured for float16 detector with $numCores threads")
        } catch (e: Exception) {
            Log.w(TAG, "XNNPack failed for FP16: ${e.message}, using basic CPU...")
            accelerationType = "CPU (FP16, $numCores threads)"
        }
    }
    
    // Configure for Float32 models - XNNPack primary (same GPU partitioning issue as FP16)
    private fun Interpreter.Options.configureForFloat32() {
        val numCores = Runtime.getRuntime().availableProcessors()
        setNumThreads(numCores)
        try {
            setUseXNNPACK(true)
            accelerationType = "XNNPack (FP32, $numCores threads)"
            Log.d(TAG, "✅ XNNPack configured for float32 detector with $numCores threads")
        } catch (e: Exception) {
            Log.w(TAG, "XNNPack failed for FP32: ${e.message}, using basic CPU...")
            accelerationType = "CPU (FP32, $numCores threads)"
        }
    }

    // ========== TFLite Interpreter ==========
    // Use protected var interpreter: Interpreter? = null from BasePredictor if available
    // Otherwise, keep it in this class as usual
    init {
        val assetManager = context.assets
        val modelBuffer  = YOLOUtils.loadModelFile(context, modelPath)

        /* --- Get labels from metadata (try Appended ZIP → FlatBuffers in order) --- */
        var loadedLabels = YOLOFileUtils.loadLabelsFromAppendedZip(context, modelPath)
        var labelsWereLoaded = loadedLabels != null

        if (labelsWereLoaded) {
            this.labels = loadedLabels!! // Use labels from appended ZIP
            Log.i(TAG, "Labels successfully loaded from appended ZIP.")
        } else {
            Log.w(TAG, "Could not load labels from appended ZIP, trying FlatBuffers metadata...")
            // Try FlatBuffers as a fallback
            if (loadLabelsFromFlatbuffers(modelBuffer)) {
                labelsWereLoaded = true
                Log.i(TAG, "Labels successfully loaded from FlatBuffers metadata.")
            }
        }

        if (!labelsWereLoaded) {
            Log.w(TAG, "No embedded labels found from appended ZIP or FlatBuffers. Using labels passed via constructor (if any) or an empty list.")
            // If labels were passed via constructor and not overridden, they will be used.
            // If no labels were passed and none loaded, this.labels will be what was passed or an uninitialized/empty list
            // depending on how the 'labels' property was handled if it was nullable or had a default.
            // Given 'override var labels: List<String>' is passed in constructor, it will hold the passed value.
            if (this.labels.isEmpty()) {
                 Log.w(TAG, "Warning: No labels loaded and no labels provided via constructor. Detections might lack class names.")
            }
        }

        // Create interpreter options based on model type (quantized vs float)
        // Try with delegate first, fallback to XNNPack CPU if delegate fails
        interpreter = try {
            val interpreterOptions = createInterpreterOptions(modelPath)
            Interpreter(modelBuffer, interpreterOptions)
        } catch (e: Exception) {
            Log.w(TAG, "⚠️ Delegate failed, falling back to XNNPack CPU: ${e.message}")
            // Release any delegate that was created
            nnApiDelegate?.close()
            nnApiDelegate = null
            gpuDelegate?.close()
            gpuDelegate = null
            // Create new options with only XNNPack (no delegates)
            val fallbackOptions = (customOptions ?: Interpreter.Options()).apply {
                val numCores = Runtime.getRuntime().availableProcessors()
                setNumThreads(numCores)
                try {
                    setUseXNNPACK(true)
                } catch (_: Exception) {}
            }
            accelerationType = "CPU (XNNPack fallback, ${Runtime.getRuntime().availableProcessors()} threads)"
            Interpreter(modelBuffer, fallbackOptions)
        }
        // Call allocateTensors() once during initialization, not in the inference loop
        interpreter.allocateTensors()
        Log.i(TAG, "🚀 TFLite model loaded: $modelPath")
        Log.i(TAG, "⚡ Acceleration: $accelerationType")

        // Check input shape (example: [1, inHeight, inWidth, 3])
        val inputShape = interpreter.getInputTensor(0).shape()
        val inBatch = inputShape[0]         // Usually 1
        val inHeight = inputShape[1]        // Example: 320
        val inWidth = inputShape[2]         // Example: 320
        val inChannels = inputShape[3]      // 3 (RGB)
        require(inBatch == 1 && inChannels == 3) {
            "Input tensor shape not supported. Expected [1, H, W, 3]. But got ${inputShape.joinToString()}"
        }
        inputSize = Size(inWidth, inHeight) // Set variable in BasePredictor
        modelInputSize = Pair(inWidth, inHeight)
        Log.d("TAG", "Model input size = $inWidth x $inHeight")

        // Output shape (varies by model, modify as needed)
        // Example: [1, 84, 2100] = [batch, outHeight, outWidth]
        val outputShape = interpreter.getOutputTensor(0).shape()
        out1 = outputShape[1] // 84
        out2 = outputShape[2] // 2100
        Log.d("TAG", "Model output shape = [1, $out1, $out2]")

        // Allocate preprocessing resources
        initPreprocessingResources(inWidth, inHeight)

        // Allocate inference output arrays
        rawOutput = Array(1) { Array(out1) { FloatArray(out2) } }
        predictions = Array(out2) { FloatArray(out1) }
        
        // Initialize reusable TensorImage
        reusableTensorImage = TensorImage(DataType.FLOAT32)
        
        // Initialize image processors with NEAREST_NEIGHBOR for speed (vs BILINEAR for quality)
        // NEAREST_NEIGHBOR is ~2x faster with minimal quality loss for YOLO
        
        // 1. For camera feed in portrait mode - includes 270-degree rotation
        imageProcessorCameraPortrait = ImageProcessor.Builder()
            .add(Rot90Op(3))  // 270-degree rotation (3 * 90 degrees) for back camera
            .add(ResizeOp(inputSize.height, inputSize.width, ResizeOp.ResizeMethod.NEAREST_NEIGHBOR))
            .add(NormalizeOp(INPUT_MEAN, INPUT_STANDARD_DEVIATION))
            .add(CastOp(INPUT_IMAGE_TYPE))
            .build()
            
        // 2. For front camera in portrait mode - 90-degree rotation
        imageProcessorCameraPortraitFront = ImageProcessor.Builder()
            .add(Rot90Op(1))  // 90-degree rotation for front camera
            .add(ResizeOp(inputSize.height, inputSize.width, ResizeOp.ResizeMethod.NEAREST_NEIGHBOR))
            .add(NormalizeOp(INPUT_MEAN, INPUT_STANDARD_DEVIATION))
            .add(CastOp(INPUT_IMAGE_TYPE))
            .build()
            
        // 3. For camera feed in landscape mode - no rotation needed
        imageProcessorCameraLandscape = ImageProcessor.Builder()
            .add(ResizeOp(inputSize.height, inputSize.width, ResizeOp.ResizeMethod.NEAREST_NEIGHBOR))
            .add(NormalizeOp(INPUT_MEAN, INPUT_STANDARD_DEVIATION))
            .add(CastOp(INPUT_IMAGE_TYPE))
            .build()
            
        // 4. For single images - keep BILINEAR for better quality on static images
        imageProcessorSingleImage = ImageProcessor.Builder()
            .add(ResizeOp(inputSize.height, inputSize.width, ResizeOp.ResizeMethod.BILINEAR))
            .add(NormalizeOp(INPUT_MEAN, INPUT_STANDARD_DEVIATION))
            .add(CastOp(INPUT_IMAGE_TYPE))
            .build()
        
        // Warmup the model with dummy inference to stabilize performance
        performWarmup(inWidth, inHeight)
            
        Log.d("TAG", "ObjectDetector initialized.")
    }
    
    /**
     * Perform warmup inference runs to stabilize GPU/NNAPI performance
     * This eliminates the cold-start latency spike on first inference
     */
    private fun performWarmup(width: Int, height: Int) {
        try {
            // Create a small dummy bitmap for warmup
            val dummyBitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
            val warmupTensorImage = TensorImage(DataType.FLOAT32)
            warmupTensorImage.load(dummyBitmap)
            
            val warmupProcessed = imageProcessorSingleImage.process(warmupTensorImage)
            val warmupBuffer = warmupProcessed.buffer
            warmupBuffer.rewind()
            
            // Run 2 warmup inferences (reduced from 5 to avoid ANR)
            val warmupCount = 2
            repeat(warmupCount) {
                interpreter.run(warmupBuffer, rawOutput)
                warmupBuffer.rewind()
            }
            
            dummyBitmap.recycle()
            Log.d(TAG, "🔥 Warmup completed ($warmupCount runs) - model ready for stable inference")
        } catch (e: Exception) {
            Log.w(TAG, "Warmup failed (non-critical): ${e.message}")
        }
    }

    /* =================================================================== */
    /*                 metadata helper functions (Kotlin)                 */
    /* =================================================================== */

    // Old ZIP loading methods (readWholeModel, findPKHeader, loadLabelsFromEmbeddedZip)
    // have been removed as their functionality is replaced by YOLOFileUtils.loadLabelsFromAppendedZip

    /**
     * ────────────────────────────────────────────────────────────────
     *  Load labels from FlatBuffers (metadata.yaml) - based on old code
     *  - Scan all associatedFileNames
     *  - Parse YAML as Map<Int,String>
     *  - Use values directly as List and assign to labels
     * ────────────────────────────────────────────────────────────────
     */
    private fun loadLabelsFromFlatbuffers(buf: MappedByteBuffer): Boolean = try {
        val extractor = MetadataExtractor(buf)
        val files = extractor.associatedFileNames
        if (!files.isNullOrEmpty()) {
            for (fileName in files) {
                Log.d(TAG, "Found associated file: $fileName")
                extractor.getAssociatedFile(fileName)?.use { stream ->
                    val fileString = String(stream.readBytes(), Charsets.UTF_8)
                    Log.d(TAG, "Associated file contents:\n$fileString")

                    val yaml = Yaml()
                    @Suppress("UNCHECKED_CAST")
                    val data = yaml.load<Map<String, Any>>(fileString)
                    if (data != null && data.containsKey("names")) {
                        val namesMap = data["names"] as? Map<Int, String>
                        if (namesMap != null) {
                            labels = namesMap.values.toList()          // Same as old code
                            Log.d(TAG, "Loaded labels from metadata: $labels")
                            return true
                        }
                    }
                }
            }
        } else {
            Log.d(TAG, "No associated files found in the metadata.")
        }
        false
    } catch (e: Exception) {
        Log.e(TAG, "Failed to extract metadata: ${e.message}")
        false
    }


    private fun initPreprocessingResources(width: Int, height: Int) {
        // ARGB_8888 Bitmap for input size (e.g., 320x320)
        scaledBitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)

        // Int array for pixel reading
        intValues = IntArray(width * height)

        // Buffer for TFLite input
        inputBuffer = ByteBuffer.allocateDirect(1 * width * height * 3 * 4).apply {
            order(ByteOrder.nativeOrder())
        }
    }

    /**
     * Main inference method - OPTIMIZED FOR 30+ FPS
     * - Preprocessing: resize bitmap via ImageProcessor
     * - TFLite run with GPU/NNAPI acceleration
     * - Postprocessing (NMS via JNI)
     * @param bitmap Input bitmap to process
     * @param origWidth Original width of the source image
     * @param origHeight Original height of the source image
     * @param rotateForCamera Whether this is a camera feed that requires rotation (true) or a single image (false)
     * @return YOLOResult containing detection results
     */
    override fun predict(bitmap: Bitmap, origWidth: Int, origHeight: Int, rotateForCamera: Boolean, isLandscape: Boolean): YOLOResult {
        val overallStartTime = System.nanoTime()

        // ======== Preprocessing: Convert Bitmap to ByteBuffer via reusable TensorImage ========
        // Reuse TensorImage to avoid allocation overhead
        reusableTensorImage.load(bitmap)

        // Apply rotation for camera frames, process without rotation for single images
        val processedImage = if (rotateForCamera) {
            // Use appropriate camera processor based on orientation
            if (isLandscape) {
                imageProcessorCameraLandscape.process(reusableTensorImage)
            } else {
                // Use different rotation for front vs back camera
                if (isFrontCamera) {
                    imageProcessorCameraPortraitFront.process(reusableTensorImage)
                } else {
                    imageProcessorCameraPortrait.process(reusableTensorImage)
                }
            }
        } else {
            // Use single image processor (no rotation) for regular images
            imageProcessorSingleImage.process(reusableTensorImage)
        }
        
        // Use processedImage buffer directly for inference (avoid extra copy)
        val inferenceBuffer = processedImage.buffer
        inferenceBuffer.rewind()
        
        val preprocessEndTime = System.nanoTime()

        // ======== Inference ============
        interpreter.run(inferenceBuffer, rawOutput)
        val inferenceEndTime = System.nanoTime()

        // ======== Post-processing ============
        val outHeight = rawOutput[0].size      // out1
        val outWidth = rawOutput[0][0].size    // out2

        val resultBoxes = postprocess(
            rawOutput[0],
            w = outWidth,   // width is out2
            h = outHeight,  // height is out1
            confidenceThreshold = confidenceThreshold,
            iouThreshold = iouThreshold,
            numItemsThreshold = numItemsThreshold,
            numClasses = labels.size
        )
        
        // Convert to Box list
        val boxes = mutableListOf<Box>()
        for (boxArray in resultBoxes) {
            if (boxArray.size >= 6) {
                // Create xywh (absolute pixel coordinates)
                val rect = RectF(
                    boxArray[0] * origWidth,                    // x
                    boxArray[1] * origHeight,                   // y
                    (boxArray[0] + boxArray[2]) * origWidth,    // right
                    (boxArray[1] + boxArray[3]) * origHeight    // bottom
                )
                
                // Create xywhn (normalized coordinates 0-1)
                val normRect = RectF(
                    boxArray[0],                    // normalized x
                    boxArray[1],                    // normalized y
                    boxArray[0] + boxArray[2],      // normalized right
                    boxArray[1] + boxArray[3]       // normalized bottom
                )
                
                // Ensure coordinates are valid
                if (rect.left >= 0 && rect.top >= 0 && 
                    rect.right <= origWidth && rect.bottom <= origHeight &&
                    rect.width() > 0 && rect.height() > 0) {
                    
                    val classIdx = boxArray[5].toInt()
                    val label = if (classIdx in labels.indices) labels[classIdx] else "Unknown"
                    boxes.add(Box(classIdx, label, boxArray[4], rect, normRect))
                }
            }
        }

        val postprocessEndTime = System.nanoTime()
        
        // Calculate times
        val preprocessTimeMs = (preprocessEndTime - overallStartTime) / 1_000_000.0
        val inferenceTimeMs = (inferenceEndTime - preprocessEndTime) / 1_000_000.0
        val postprocessTimeMs = (postprocessEndTime - inferenceEndTime) / 1_000_000.0
        val totalMs = (postprocessEndTime - overallStartTime) / 1_000_000.0
        val instantFps = if (totalMs > 0) 1000.0 / totalMs else 0.0
        
        // Log only every ~30 frames to reduce overhead (approximately once per second)
        if (System.currentTimeMillis() % 1000 < 33) {
            Log.d(TAG, "⚡ ${totalMs.toInt()}ms (~${instantFps.toInt()}fps) Pre:${preprocessTimeMs.toInt()}, Inf:${inferenceTimeMs.toInt()} Boxes:${boxes.size}")
        }

        updateTiming() // This updates t0, t1, t2, t3, t4 based on its own logic

        return YOLOResult(
            origShape = com.ultralytics.yolo.Size(origWidth, origHeight),
            boxes = boxes,
            speed = totalMs, // Actual processing time in milliseconds for this frame
            fps = instantFps, // Use instant FPS based on actual processing time
            names = labels
        )
    }

    // Thresholds (like setConfidenceThreshold, setIouThreshold in TFLiteDetector)
    private var confidenceThreshold = 0.25f
    private var iouThreshold = 0.4f
//    private var numItemsThreshold = 30

    override fun setConfidenceThreshold(conf: Double) {
        confidenceThreshold = conf.toFloat()
        super.setConfidenceThreshold(conf)
    }

    override fun setIouThreshold(iou: Double) {
        iouThreshold = iou.toFloat()
        super.setIouThreshold(iou)
    }

    override fun getConfidenceThreshold(): Double {
        return confidenceThreshold.toDouble()
    }

    override fun getIouThreshold(): Double {
        return iouThreshold.toDouble()
    }

    override fun close() {
        // Clean up delegates before closing interpreter
        gpuDelegate?.close()
        gpuDelegate = null
        nnApiDelegate?.close()
        nnApiDelegate = null
        super.close()
    }

    override fun setNumItemsThreshold(n: Int) {
        numItemsThreshold = n
        super.setNumItemsThreshold(n)
    }

    // Post-processing via JNI
    private external fun postprocess(
        predictions: Array<FloatArray>,
        w: Int,
        h: Int,
        confidenceThreshold: Float,
        iouThreshold: Float,
        numItemsThreshold: Int,
        numClasses: Int
    ): Array<FloatArray>

    companion object {
        private const val TAG = "ObjectDetector"
        // Load JNI library
        init {
            System.loadLibrary("ultralytics")
        }
        private const val INPUT_MEAN = 0f
        private const val INPUT_STANDARD_DEVIATION = 255f
        private val INPUT_IMAGE_TYPE = DataType.FLOAT32
        private val OUTPUT_IMAGE_TYPE = DataType.FLOAT32
        private const val CONFIDENCE_THRESHOLD = 0.25F
        private const val IOU_THRESHOLD = 0.4F
    }
}