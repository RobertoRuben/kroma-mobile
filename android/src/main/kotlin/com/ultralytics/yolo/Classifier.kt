// Ultralytics 🚀 AGPL-3.0 License - https://ultralytics.com/license

package com.ultralytics.yolo

import android.content.Context
import android.graphics.Bitmap
import android.util.Log
import org.tensorflow.lite.DataType
import org.tensorflow.lite.Interpreter
import org.tensorflow.lite.gpu.GpuDelegate
import org.tensorflow.lite.support.common.FileUtil
import org.tensorflow.lite.support.common.ops.CastOp
import org.tensorflow.lite.support.common.ops.NormalizeOp
import org.tensorflow.lite.support.image.ImageProcessor
import org.tensorflow.lite.support.image.TensorImage
import org.tensorflow.lite.support.image.ops.ResizeOp
import org.tensorflow.lite.support.image.ops.Rot90Op
import org.tensorflow.lite.support.metadata.MetadataExtractor
import org.tensorflow.lite.support.metadata.schema.ModelMetadata
import org.yaml.snakeyaml.Yaml
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.MappedByteBuffer

class Classifier(
    context: Context,
    modelPath: String,
    override var labels: List<String> = emptyList(),
    private val useGpu: Boolean = true,
    private val customOptions: Interpreter.Options? = null,
    private val classifierOptions: Map<String, Any>? = null
) : BasePredictor() {

    private val interpreterOptions: Interpreter.Options = (customOptions ?: Interpreter.Options()).apply {
        val numCores = Runtime.getRuntime().availableProcessors()
        
        // If no custom options provided, use optimal thread count
        if (customOptions == null) {
            setNumThreads(numCores.coerceIn(2, 4))
        }
        
        // Enable XNNPack for faster CPU execution
        try {
            setUseXNNPACK(true)
        } catch (e: Exception) {
            Log.d(TAG, "XNNPack not available: ${e.message}")
        }
        
        // Add optimized GPU delegate if requested
        if (useGpu) {
            try {
                val gpuOptions = GpuDelegate.Options().apply {
                    setPrecisionLossAllowed(true)  // FP16 precision for faster inference
                    setInferencePreference(GpuDelegate.Options.INFERENCE_PREFERENCE_FAST_SINGLE_ANSWER)
                }
                addDelegate(GpuDelegate(gpuOptions))
                // Reduce CPU threads when GPU handles compute
                setNumThreads(2.coerceAtMost(numCores))
                Log.d(TAG, "GPU delegate configured with FP16 precision + FAST_SINGLE_ANSWER")
            } catch (e: Exception) {
                Log.e(TAG, "GPU delegate error: ${e.message}, using XNNPack CPU fallback")
            }
        }
    }

    var numClass: Int = 0
    private var modelInputChannels: Int = 3  // Default to 3-channel, will be detected
    private var isGrayscaleModel: Boolean = false

    private lateinit var imageProcessorCameraPortrait: ImageProcessor
    private lateinit var imageProcessorCameraPortraitFront: ImageProcessor
    private lateinit var imageProcessorCameraLandscape: ImageProcessor
    private lateinit var imageProcessorSingleImage: ImageProcessor

    init {
        val modelBuffer = YOLOUtils.loadModelFile(context, modelPath)

        // ===== Load label information (try Appended ZIP → FlatBuffers in order) =====
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
            
            // Check if labels are provided via classifierOptions
            val optionsLabels = classifierOptions?.get("labels") as? List<*>
            if (optionsLabels != null) {
                this.labels = optionsLabels.map { it.toString() }
                Log.i(TAG, "Using labels from classifierOptions (${this.labels.size} classes): ${this.labels}")
            } else if (this.labels.isEmpty()) {
                Log.w(TAG, "Warning: No labels loaded and no labels provided via constructor or classifierOptions. Detections might lack class names.")
            }
        }

        interpreter = Interpreter(modelBuffer, interpreterOptions)
        interpreter.allocateTensors()  // Pre-allocate tensors for faster first inference

        val inputShape = interpreter.getInputTensor(0).shape()
        val inBatch = inputShape[0]
        val inHeight = inputShape[1]
        val inWidth = inputShape[2]
        val inChannels = inputShape[3]
        
        // Detect model input channels and configure accordingly
        modelInputChannels = inChannels
        
        // Check if 1-channel support is enabled via classifier options
        val enable1ChannelSupport = classifierOptions?.get("enable1ChannelSupport") as? Boolean ?: false
        isGrayscaleModel = (inChannels == 1) || (enable1ChannelSupport && inChannels == 1)
        
        // Validate input shape based on detected or expected channels
        val expectedChannels = classifierOptions?.get("expectedChannels") as? Int ?: inChannels
        require(inBatch == 1) {
            "Unexpected batch size. Expect batch=1, but got batch=$inBatch"
        }
        require(inChannels == expectedChannels || (expectedChannels == 1 && inChannels == 1) || (expectedChannels == 3 && inChannels == 3)) {
            "Unexpected input channels. Expected $expectedChannels channels, but got $inChannels channels. Input shape: ${inputShape.joinToString()}"
        }
        
        Log.d(TAG, "Model configuration: ${inChannels}-channel input, grayscale mode: $isGrayscaleModel")

        inputSize = Size(inWidth, inHeight)
        modelInputSize = Pair(inWidth, inHeight)
        Log.d(TAG, "Model input size = $inWidth x $inHeight")

        val outputShape = interpreter.getOutputTensor(0).shape()
        // e.g. outputShape = [1, 1000] for ImageNet, [1, 12] for EMNIST
        numClass = outputShape[1]
        
        // Validate expected classes if specified
        (classifierOptions?.get("expectedClasses") as? Int)?.let { expectedClasses ->
            if (numClass != expectedClasses) {
                Log.w(TAG, "Warning: Expected $expectedClasses output classes, but model has $numClass classes")
            }
        }
        
        Log.d(TAG, "Model output shape = [1, $numClass] (${if (isGrayscaleModel) "grayscale" else "RGB"} model)")

        // Setup ImageProcessors only for RGB models (3-channel)
        // For grayscale models (1-channel), we'll use custom processing
        if (!isGrayscaleModel) {
        // For camera feed in portrait mode (with rotation)
        imageProcessorCameraPortrait = ImageProcessor.Builder()
            .add(Rot90Op(3))  // 270-degree rotation for back camera
            .add(ResizeOp(inHeight, inWidth, ResizeOp.ResizeMethod.BILINEAR))
            .add(NormalizeOp(INPUT_MEAN, INPUT_STD))
            .add(CastOp(DataType.FLOAT32))
            .build()
            
        // For front camera in portrait mode (90-degree rotation)
        imageProcessorCameraPortraitFront = ImageProcessor.Builder()
            .add(Rot90Op(1))  // 90-degree rotation for front camera
            .add(ResizeOp(inHeight, inWidth, ResizeOp.ResizeMethod.BILINEAR))
            .add(NormalizeOp(INPUT_MEAN, INPUT_STD))
            .add(CastOp(DataType.FLOAT32))
            .build()
            
        // For camera feed in landscape mode (no rotation)
        imageProcessorCameraLandscape = ImageProcessor.Builder()
            .add(ResizeOp(inHeight, inWidth, ResizeOp.ResizeMethod.BILINEAR))
            .add(NormalizeOp(INPUT_MEAN, INPUT_STD))
            .add(CastOp(DataType.FLOAT32))
            .build()
            
        // For single images (no rotation) - NEAREST_NEIGHBOR is 2x faster for evaluation crops
        imageProcessorSingleImage = ImageProcessor.Builder()
            .add(ResizeOp(inHeight, inWidth, ResizeOp.ResizeMethod.NEAREST_NEIGHBOR))
            .add(NormalizeOp(INPUT_MEAN, INPUT_STD))
            .add(CastOp(DataType.FLOAT32))
            .build()
        }

        Log.d(TAG, "Classifier initialized.")

        // Warmup: 1 inference run to avoid cold-start latency on first classification
        performWarmup(inWidth, inHeight)
    }

    /**
     * Runs a single warmup inference to prime the TFLite interpreter
     */
    private fun performWarmup(width: Int, height: Int) {
        try {
            if (isGrayscaleModel) {
                // Create a small dummy grayscale buffer
                val dummyBuffer = java.nio.ByteBuffer.allocateDirect(width * height * 4)
                dummyBuffer.order(java.nio.ByteOrder.nativeOrder())
                val outputArray = Array(1) { FloatArray(numClass) }
                interpreter.run(dummyBuffer, outputArray)
                Log.d(TAG, "Warmup completed (1 run, grayscale)")
            } else {
                val dummyBitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
                val warmupTensorImage = org.tensorflow.lite.support.image.TensorImage(org.tensorflow.lite.DataType.FLOAT32)
                warmupTensorImage.load(dummyBitmap)
                val warmupProcessed = imageProcessorSingleImage.process(warmupTensorImage)
                val warmupBuffer = warmupProcessed.buffer
                warmupBuffer.rewind()
                val outputArray = Array(1) { FloatArray(numClass) }
                interpreter.run(warmupBuffer, outputArray)
                dummyBitmap.recycle()
                Log.d(TAG, "Warmup completed (1 run, RGB)")
            }
        } catch (e: Exception) {
            Log.w(TAG, "Classifier warmup failed (non-critical): ${e.message}")
        }
    }

    // Pre-allocated output buffer to avoid GC pressure on each predict() call
    private lateinit var reusableOutputArray: Array<FloatArray>
    private var reusableTensorImage: TensorImage? = null

    override fun predict(bitmap: Bitmap, origWidth: Int, origHeight: Int, rotateForCamera: Boolean, isLandscape: Boolean): YOLOResult {
        t0 = System.nanoTime()

        val inputBuffer: ByteBuffer
        
        if (isGrayscaleModel && classifierOptions != null) {
            // Use custom grayscale processing for 1-channel models
            val modelInputSize = inputSize
            
            // Extract options from classifierOptions map
            val enableColorInversion = classifierOptions["enableColorInversion"] as? Boolean ?: false
            val enableMaxNormalization = classifierOptions["enableMaxNormalization"] as? Boolean ?: false
            val inputMean = (classifierOptions["inputMean"] as? Number)?.toFloat() ?: 0f
            val inputStd = (classifierOptions["inputStd"] as? Number)?.toFloat() ?: 255f
            
            inputBuffer = ImageUtils.processGrayscaleImage(
                bitmap = bitmap,
                targetWidth = modelInputSize.width,
                targetHeight = modelInputSize.height,
                enableColorInversion = enableColorInversion,
                enableMaxNormalization = enableMaxNormalization,
                inputMean = inputMean,
                inputStd = inputStd
            )
        } else {
            // Reuse TensorImage to avoid allocation per frame
            val tensorImage = reusableTensorImage ?: TensorImage(DataType.FLOAT32).also { reusableTensorImage = it }
            tensorImage.load(bitmap)
        
        // Choose appropriate processor based on input source and orientation
        val processedImage = if (rotateForCamera) {
            // Apply appropriate rotation based on device orientation
            if (isLandscape) {
                imageProcessorCameraLandscape.process(tensorImage)
            } else {
                // Use different rotation for front vs back camera
                if (isFrontCamera) {
                    imageProcessorCameraPortraitFront.process(tensorImage)
                } else {
                    imageProcessorCameraPortrait.process(tensorImage)
                }
            }
        } else {
            // No rotation for single image
            imageProcessorSingleImage.process(tensorImage)
        }
            inputBuffer = processedImage.buffer
        }

        // Reuse output array to reduce GC pressure
        if (!::reusableOutputArray.isInitialized || reusableOutputArray[0].size != numClass) {
            reusableOutputArray = Array(1) { FloatArray(numClass) }
        }
        interpreter.run(inputBuffer, reusableOutputArray)

        updateTiming()

        val scores = reusableOutputArray[0]   // FloatArray(numClass)
        val indexedScores = scores.mapIndexed { index, score -> index to score }
        val sorted = indexedScores.sortedByDescending { it.second }

        // Top1
        val top1 = sorted.firstOrNull()
        // Top5
        val top5 = sorted.take(5)

        val top1Label = if (top1 != null) labels.getOrElse(top1.first) { "Unknown" } else "Unknown"
        val top1Score = top1?.second ?: 0f
        val top1Index: Int = if (top1 != null) top1.first else 0

        val top5Labels = top5.map { (idx, _) -> labels.getOrElse(idx) { "Unknown" } }
        val top5Scores = top5.map { it.second }

        val probs = Probs(
            top1Label = top1Label,
            top5Labels = top5Labels,
            top1Conf = top1Score,
            top5Confs = top5Scores,
            top1Index = top1Index
        )

        val fpsVal = if (t4 > 0) 1.0 / t4 else 0.0

        Log.d(TAG, "Classification result: top1Label=${probs.top1Label}, top1Conf=${probs.top1Conf}, top1Index=${probs.top1Index}")
        Log.d(TAG, "Labels: ${labels}")
        Log.d(TAG, "Prediction completed successfully")

        return YOLOResult(
            origShape = Size(origWidth, origHeight),
            probs = probs,
            speed = t2,
            fps = fpsVal,
            names = labels
        )
    }

    companion object {
        private const val TAG = "Classifier"

        private const val INPUT_MEAN = 0f
        private const val INPUT_STD = 255f
    }
    
    /**
     * Load labels from FlatBuffers metadata
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
                            labels = namesMap.values.toList()
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
}
