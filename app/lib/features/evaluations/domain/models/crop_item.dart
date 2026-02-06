import 'dart:typed_data';
import 'dart:ui';

/// Represents a cropped detection from an image
class CropItem {
  const CropItem({
    required this.id,
    required this.imageBytes,
    required this.boundingBox,
    required this.confidence,
    required this.className,
    this.classificationResult,
    this.isSelected = true,
  });

  /// Unique identifier for this crop
  final String id;

  /// The cropped image data
  final Uint8List imageBytes;

  /// Original bounding box coordinates (normalized 0-1)
  final Rect boundingBox;

  /// Detection confidence score
  final double confidence;

  /// Detection class name
  final String className;

  /// Classification result after running classifier
  final ClassificationResult? classificationResult;

  /// Whether this crop is selected (not deleted)
  final bool isSelected;

  /// Creates a copy with updated fields
  CropItem copyWith({
    String? id,
    Uint8List? imageBytes,
    Rect? boundingBox,
    double? confidence,
    String? className,
    ClassificationResult? classificationResult,
    bool? isSelected,
  }) {
    return CropItem(
      id: id ?? this.id,
      imageBytes: imageBytes ?? this.imageBytes,
      boundingBox: boundingBox ?? this.boundingBox,
      confidence: confidence ?? this.confidence,
      className: className ?? this.className,
      classificationResult: classificationResult ?? this.classificationResult,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CropItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Result from classification model
class ClassificationResult {
  const ClassificationResult({
    required this.className,
    required this.confidence,
    required this.classIndex,
  });

  final String className;
  final double confidence;
  final int classIndex;

  /// Get display label with confidence
  String get displayLabel => '$className ${(confidence * 100).toStringAsFixed(0)}%';
}
