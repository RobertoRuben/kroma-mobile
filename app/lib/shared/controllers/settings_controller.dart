import 'package:flutter/foundation.dart';
import 'package:ultralytics_yolo_example/shared/models/models.dart';

/// Controller for managing app-wide inference settings (singleton).
///
/// This controller manages:
/// - Detector model selection (int8, float16, float32)
/// - Classifier model selection
/// - Confidence threshold
class SettingsController extends ChangeNotifier {
  SettingsController._();

  static final SettingsController instance = SettingsController._();

  /// Initialize with current preloader state (call once at startup)
  void initialize({
    ModelType? initialDetector,
    ModelType? initialClassifier,
    double? initialConfidence,
  }) {
    _selectedDetector = initialDetector ?? ModelType.detectorInt8;
    _selectedClassifier = initialClassifier ?? ModelType.maturityFloat16;
    _confidenceThreshold = initialConfidence ?? 0.5;
  }

  ModelType _selectedDetector = ModelType.detectorInt8;
  ModelType _selectedClassifier = ModelType.maturityFloat16;
  double _confidenceThreshold = 0.5;

  /// Currently selected detector model
  ModelType get selectedDetector => _selectedDetector;

  /// Currently selected classifier model
  ModelType get selectedClassifier => _selectedClassifier;

  /// Current confidence threshold (0.0 - 1.0)
  double get confidenceThreshold => _confidenceThreshold;

  /// Available detector models
  static List<ModelType> get detectorModels => [
        ModelType.detectorInt8,
        ModelType.detectorFloat16,
        ModelType.detectorFloat32,
      ];

  /// Available classifier models
  static List<ModelType> get classifierModels => [
        ModelType.maturityFloat16,
        ModelType.maturityFloat32,
      ];

  /// Updates the selected detector model
  void setDetector(ModelType detector) {
    if (!detector.isDetector) return;
    if (_selectedDetector != detector) {
      _selectedDetector = detector;
      notifyListeners();
    }
  }

  /// Updates the selected classifier model
  void setClassifier(ModelType classifier) {
    if (!classifier.isClassifier) return;
    if (_selectedClassifier != classifier) {
      _selectedClassifier = classifier;
      notifyListeners();
    }
  }

  /// Updates the confidence threshold
  void setConfidenceThreshold(double threshold) {
    final clampedThreshold = threshold.clamp(0.0, 1.0);
    if ((_confidenceThreshold - clampedThreshold).abs() > 0.01) {
      _confidenceThreshold = clampedThreshold;
      notifyListeners();
    }
  }

  /// Resets all settings to defaults
  void resetToDefaults() {
    _selectedDetector = ModelType.detectorInt8;
    _selectedClassifier = ModelType.maturityFloat16;
    _confidenceThreshold = 0.5;
    notifyListeners();
  }
}
