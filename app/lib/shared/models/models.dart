import 'package:ultralytics_yolo/models/yolo_task.dart';

/// Available model types for inference
enum ModelType {
  // Detector models
  detectorFloat32('detector_best_float32', YOLOTask.detect),
  detectorFloat16('detector_best_float16', YOLOTask.detect),
  detectorInt8('detector_best_int8', YOLOTask.detect),
  // Classifier models
  maturityFloat16('maturity_cls_best_float16', YOLOTask.classify),
  maturityFloat32('maturiy_cls_best_float32', YOLOTask.classify);

  final String modelName;
  final YOLOTask task;

  const ModelType(this.modelName, this.task);

  String get displayName {
    switch (this) {
      case ModelType.detectorFloat32:
        return 'Detector Float32';
      case ModelType.detectorFloat16:
        return 'Detector Float16';
      case ModelType.detectorInt8:
        return 'Detector Int8';
      case ModelType.maturityFloat16:
        return 'Madurez Float16';
      case ModelType.maturityFloat32:
        return 'Madurez Float32';
    }
  }

  /// Returns true if this is a detector model
  bool get isDetector => task == YOLOTask.detect;

  /// Returns true if this is a classifier model
  bool get isClassifier => task == YOLOTask.classify;
}

enum SliderType { none, numItems, confidence, iou }
