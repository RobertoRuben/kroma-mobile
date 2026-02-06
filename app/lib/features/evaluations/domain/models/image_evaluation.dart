import 'dart:typed_data';

import 'package:ultralytics_yolo_example/features/evaluations/domain/models/crop_item.dart';

/// Represents the evaluation data for a single image
class ImageEvaluation {
  ImageEvaluation({
    required this.id,
    required this.originalImage,
    required this.imageWidth,
    required this.imageHeight,
    required this.crops,
    this.annotatedImage,
  });

  /// Unique identifier (e.g., "img_0", "img_1"...)
  final String id;

  /// Original image bytes
  final Uint8List originalImage;

  /// Image dimensions
  final int imageWidth;
  final int imageHeight;

  /// Detected crop items for this image
  List<CropItem> crops;

  /// Annotated image after classification (generated on finalize)
  Uint8List? annotatedImage;

  /// Number of selected crops in this image
  int get selectedCount => crops.where((c) => c.isSelected).length;

  /// Total crops detected in this image
  int get totalCount => crops.length;

  /// Selected crops only
  List<CropItem> get selectedCrops => crops.where((c) => c.isSelected).toList();

  /// Get classification stats for this image
  Map<String, int> getClassificationStats() {
    final stats = <String, int>{};
    for (final crop in selectedCrops) {
      final label = crop.classificationResult?.className ?? 'Sin clasificar';
      stats[label] = (stats[label] ?? 0) + 1;
    }
    return stats;
  }

  /// Get average confidence for classifications in this image
  double getAverageConfidence() {
    final classified =
        selectedCrops.where((c) => c.classificationResult != null).toList();
    if (classified.isEmpty) return 0;
    final total = classified.fold<double>(
      0,
      (sum, c) => sum + (c.classificationResult?.confidence ?? 0),
    );
    return total / classified.length;
  }
}
