import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:ultralytics_yolo/utils/map_converter.dart';
import 'package:ultralytics_yolo_example/core/services/model_preloader.dart';
import 'package:ultralytics_yolo_example/features/evaluations/domain/models/models.dart';

/// Repository for handling evaluation operations (detection and classification)
/// Uses preloaded models from ModelPreloader for better performance
class EvaluationRepository {
  EvaluationRepository();

  final ModelPreloader _preloader = ModelPreloader.instance;

  /// Run detection on image and extract crops
  /// [onCropExtracted] is called after each crop is extracted with (currentCount, totalDetections)
  Future<DetectionResult> detectAndExtractCrops(
    Uint8List imageBytes, {
    double? confidenceThreshold,
    void Function(int extracted, int total)? onCropExtracted,
  }) async {
    final detector = _preloader.detector;
    if (detector == null || !detector.isInitialized) {
      throw Exception('Detector no inicializado');
    }

    final result = await detector.predict(
      imageBytes,
      confidenceThreshold: confidenceThreshold,
    );
    final boxes = result['boxes'] is List
        ? MapConverter.convertBoxesList(result['boxes'] as List)
        : <Map<String, dynamic>>[];

    final annotatedImage = result['annotatedImage'] as Uint8List?;

    // Decode original image ONCE for dimensions and crop extraction
    final codec = await ui.instantiateImageCodec(imageBytes);
    final frame = await codec.getNextFrame();
    final decodedImage = frame.image;
    final imageWidth = decodedImage.width;
    final imageHeight = decodedImage.height;

    // Extract crops from each detection, reusing the single decoded image
    final crops = <CropItem>[];
    for (int i = 0; i < boxes.length; i++) {
      final box = boxes[i];
      final crop = await _extractCrop(
        decodedImage: decodedImage,
        box: box,
        index: i,
        imageWidth: imageWidth,
        imageHeight: imageHeight,
      );
      if (crop != null) {
        crops.add(crop);
      }
      // Report progress after each crop
      onCropExtracted?.call(i + 1, boxes.length);
    }
    decodedImage.dispose();

    return DetectionResult(
      crops: crops,
      originalImage: imageBytes,
      annotatedImage: annotatedImage,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
    );
  }

  /// Extract a single crop from the already-decoded image
  Future<CropItem?> _extractCrop({
    required ui.Image decodedImage,
    required Map<String, dynamic> box,
    required int index,
    required int imageWidth,
    required int imageHeight,
  }) async {
    try {
      // Get normalized coordinates
      final x1Norm = MapConverter.safeGetDouble(box, 'x1_norm');
      final y1Norm = MapConverter.safeGetDouble(box, 'y1_norm');
      final x2Norm = MapConverter.safeGetDouble(box, 'x2_norm');
      final y2Norm = MapConverter.safeGetDouble(box, 'y2_norm');

      // Convert to pixel coordinates
      final x1 = (x1Norm * imageWidth).round();
      final y1 = (y1Norm * imageHeight).round();
      final x2 = (x2Norm * imageWidth).round();
      final y2 = (y2Norm * imageHeight).round();

      // Ensure valid crop dimensions
      final cropWidth = x2 - x1;
      final cropHeight = y2 - y1;
      if (cropWidth <= 0 || cropHeight <= 0) return null;

      // Create crop using canvas (reuses the already-decoded image)
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      canvas.drawImageRect(
        decodedImage,
        Rect.fromLTWH(x1.toDouble(), y1.toDouble(), cropWidth.toDouble(), cropHeight.toDouble()),
        Rect.fromLTWH(0, 0, cropWidth.toDouble(), cropHeight.toDouble()),
        Paint(),
      );

      final picture = recorder.endRecording();
      final croppedImage = await picture.toImage(cropWidth, cropHeight);
      final byteData = await croppedImage.toByteData(format: ui.ImageByteFormat.png);

      croppedImage.dispose();

      if (byteData == null) return null;

      final confidence = MapConverter.safeGetDouble(box, 'confidence');
      final className = MapConverter.safeGetString(box, 'class');

      return CropItem(
        id: 'crop_$index',
        imageBytes: byteData.buffer.asUint8List(),
        boundingBox: Rect.fromLTRB(x1Norm, y1Norm, x2Norm, y2Norm),
        confidence: confidence,
        className: className,
      );
    } catch (e) {
      debugPrint('Error extracting crop: $e');
      return null;
    }
  }

  /// Classify a single crop
  Future<ClassificationResult?> classifyCrop(Uint8List cropBytes) async {
    final classifier = _preloader.classifier;
    if (classifier == null || !classifier.isInitialized) {
      throw Exception('Clasificador no inicializado');
    }

    try {
      final result = await classifier.predict(cropBytes);
      debugPrint('Classification result keys: ${result.keys.toList()}');

      // First try the 'classification' key (raw result)
      if (result.containsKey('classification')) {
        final classification = result['classification'] as Map<dynamic, dynamic>;
        debugPrint('Classification data: $classification');
        return ClassificationResult(
          className: classification['name']?.toString() ?? 'Desconocido',
          confidence: (classification['confidence'] as num?)?.toDouble() ?? 0.0,
          classIndex: (classification['class'] as num?)?.toInt() ?? 0,
        );
      }

      // Fallback: try the processed 'detections' array
      if (result.containsKey('detections')) {
        final detections = result['detections'] as List<dynamic>;
        debugPrint('Detections count: ${detections.length}');
        if (detections.isNotEmpty) {
          final detection = Map<String, dynamic>.from(detections.first as Map);
          debugPrint('Detection data: $detection');
          final className = detection['className']?.toString();
          final confidence = (detection['confidence'] as num?)?.toDouble() ?? 0.0;
          final classIndex = (detection['classIndex'] as num?)?.toInt() ?? 0;
          if (className != null && className.isNotEmpty) {
            return ClassificationResult(
              className: className,
              confidence: confidence,
              classIndex: classIndex,
            );
          }
        }
      }

      debugPrint('No classification found in result');
      return null;
    } catch (e) {
      debugPrint('Error classifying crop: $e');
      return null;
    }
  }

  /// Classify multiple crops
  Future<List<CropItem>> classifyCrops(List<CropItem> crops) async {
    final results = <CropItem>[];
    for (final crop in crops) {
      if (crop.isSelected) {
        final classification = await classifyCrop(crop.imageBytes);
        results.add(crop.copyWith(classificationResult: classification));
      } else {
        results.add(crop);
      }
    }
    return results;
  }

  /// Generate final annotated image with only selected crops and classification labels
  Future<Uint8List?> generateAnnotatedImage({
    required Uint8List originalImage,
    required List<CropItem> crops,
    required int imageWidth,
    required int imageHeight,
  }) async {
    try {
      final codec = await ui.instantiateImageCodec(originalImage);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Draw original image
      canvas.drawImage(image, Offset.zero, Paint());

      // Draw bounding boxes and labels for selected crops only
      for (final crop in crops) {
        if (!crop.isSelected) continue;

        final maturityColor =
            crop.classificationResult?.maturityColor ?? const Color(0xFFFF0000);

        final boxPaint = Paint()
          ..color = maturityColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

        final backgroundPaint = Paint()..color = maturityColor.withValues(alpha: 0.85);

        // Convert normalized to pixel coordinates
        final left = crop.boundingBox.left * imageWidth;
        final top = crop.boundingBox.top * imageHeight;
        final right = crop.boundingBox.right * imageWidth;
        final bottom = crop.boundingBox.bottom * imageHeight;

        // Draw bounding box
        canvas.drawRect(
          Rect.fromLTRB(left, top, right, bottom),
          boxPaint,
        );

        // Prepare label text
        final label = crop.classificationResult?.displayLabel ?? crop.className;

        // Draw label background and text with larger font
        final textPainter = TextPainter(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();

        final labelRect = Rect.fromLTWH(
          left,
          top - textPainter.height - 6,
          textPainter.width + 12,
          textPainter.height + 6,
        );

        // Draw rounded label background
        canvas.drawRRect(
          RRect.fromRectAndRadius(labelRect, const Radius.circular(4)),
          backgroundPaint,
        );

        // Draw label text
        textPainter.paint(canvas, Offset(left + 6, top - textPainter.height - 3));
      }

      final picture = recorder.endRecording();
      final annotatedImage = await picture.toImage(imageWidth, imageHeight);
      final byteData = await annotatedImage.toByteData(format: ui.ImageByteFormat.png);

      image.dispose();
      annotatedImage.dispose();

      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error generating annotated image: $e');
      return null;
    }
  }

  /// No need to dispose - models are managed by ModelPreloader
  void dispose() {}
}

/// Result from detection operation
class DetectionResult {
  const DetectionResult({
    required this.crops,
    required this.originalImage,
    required this.imageWidth,
    required this.imageHeight,
    this.annotatedImage,
  });

  final List<CropItem> crops;
  final Uint8List originalImage;
  final Uint8List? annotatedImage;
  final int imageWidth;
  final int imageHeight;
}
