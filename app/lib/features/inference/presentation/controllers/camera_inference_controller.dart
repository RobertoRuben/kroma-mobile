import 'package:flutter/material.dart';
import 'package:ultralytics_yolo/models/yolo_result.dart';
import 'package:ultralytics_yolo/widgets/yolo_controller.dart';
import 'package:ultralytics_yolo/utils/error_handler.dart';
import 'package:ultralytics_yolo/yolo_view.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ultralytics_yolo_example/shared/models/models.dart';
import 'package:ultralytics_yolo_example/features/inference/data/model_manager.dart';

class CameraInferenceController extends ChangeNotifier {
  CameraInferenceController({
    ModelType? initialModel,
    double? initialConfidence,
  }) {
    if (initialModel != null) {
      _selectedModel = initialModel;
    }
    if (initialConfidence != null) {
      _confidenceThreshold = initialConfidence;
    }

    _isFrontCamera = false;
    _lensFacing = LensFacing.back;

    _modelManager = ModelManager(
      onDownloadProgress: (progress) {
        _downloadProgress = progress;
        notifyListeners();
      },
      onStatusUpdate: (message) {
        _loadingMessage = message;
        notifyListeners();
      },
    );
  }

  int _detectionCount = 0;
  double _currentFps = 0.0;
  int _frameCount = 0;
  DateTime _lastFpsUpdate = DateTime.now();

  double _confidenceThreshold = 0.5;
  double _iouThreshold = 0.45;
  int _numItemsThreshold = 30;
  SliderType _activeSlider = SliderType.none;

  ModelType _selectedModel = ModelType.detectorFloat32;
  bool _isModelLoading = false;
  String? _modelPath;
  String _loadingMessage = '';
  double _downloadProgress = 0.0;
  bool _isFirstModelLoad = true;

  double _currentZoomLevel = 1.0;
  LensFacing _lensFacing = LensFacing.back;
  bool _isFrontCamera = false;

  final _yoloController = YOLOViewController();
  late final ModelManager _modelManager;

  bool _isDisposed = false;
  Future<void>? _loadingFuture;

  int get detectionCount => _detectionCount;
  double get currentFps => _currentFps;
  double get confidenceThreshold => _confidenceThreshold;
  double get iouThreshold => _iouThreshold;
  int get numItemsThreshold => _numItemsThreshold;
  SliderType get activeSlider => _activeSlider;
  ModelType get selectedModel => _selectedModel;
  bool get isModelLoading => _isModelLoading;
  String? get modelPath => _modelPath;
  String get loadingMessage => _loadingMessage;
  double get downloadProgress => _downloadProgress;
  double get currentZoomLevel => _currentZoomLevel;
  bool get isFrontCamera => _isFrontCamera;
  LensFacing get lensFacing => _lensFacing;
  YOLOViewController get yoloController => _yoloController;

  Future<void> initialize() async {
    await _requestCameraPermission();
    await _loadModelForPlatform();
    _yoloController.setThresholds(
      confidenceThreshold: _confidenceThreshold,
      iouThreshold: _iouThreshold,
      numItemsThreshold: _numItemsThreshold,
    );
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.status;
    if (!status.isGranted) {
      final result = await Permission.camera.request();
      if (!result.isGranted) {
        throw Exception('Camera permission is required to use this feature');
      }
    }
  }

  void onDetectionResults(List<YOLOResult> results) {
    if (_isDisposed) return;

    _frameCount++;
    final now = DateTime.now();
    final elapsed = now.difference(_lastFpsUpdate).inMilliseconds;

    // Update FPS calculation every 500ms for smoother display
    if (elapsed >= 500) {
      _currentFps = _frameCount * 1000 / elapsed;
      _frameCount = 0;
      _lastFpsUpdate = now;

      // Only notify when detection count or FPS actually changed
      if (_detectionCount != results.length) {
        _detectionCount = results.length;
      }
      notifyListeners();
    } else if (_detectionCount != results.length) {
      _detectionCount = results.length;
      notifyListeners();
    }
  }

  void onPerformanceMetrics(double fps) {
    if (_isDisposed) return;

    // Only notify for significant FPS changes (>1.0 difference) to reduce rebuilds
    if ((_currentFps - fps).abs() > 1.0) {
      _currentFps = fps;
      notifyListeners();
    }
  }

  void onZoomChanged(double zoomLevel) {
    if (_isDisposed) return;

    if ((_currentZoomLevel - zoomLevel).abs() > 0.01) {
      _currentZoomLevel = zoomLevel;
      notifyListeners();
    }
  }

  void toggleSlider(SliderType type) {
    if (_isDisposed) return;

    if (_activeSlider != type) {
      _activeSlider = _activeSlider == type ? SliderType.none : type;
      notifyListeners();
    }
  }

  void updateSliderValue(double value) {
    if (_isDisposed) return;

    bool changed = false;
    switch (_activeSlider) {
      case SliderType.numItems:
        final newValue = value.toInt();
        if (_numItemsThreshold != newValue) {
          _numItemsThreshold = newValue;
          _yoloController.setNumItemsThreshold(_numItemsThreshold);
          changed = true;
        }
        break;
      case SliderType.confidence:
        if ((_confidenceThreshold - value).abs() > 0.01) {
          _confidenceThreshold = value;
          _yoloController.setConfidenceThreshold(value);
          changed = true;
        }
        break;
      case SliderType.iou:
        if ((_iouThreshold - value).abs() > 0.01) {
          _iouThreshold = value;
          _yoloController.setIoUThreshold(value);
          changed = true;
        }
        break;
      default:
        break;
    }

    if (changed) {
      notifyListeners();
    }
  }

  void setZoomLevel(double zoomLevel) {
    if (_isDisposed) return;

    if ((_currentZoomLevel - zoomLevel).abs() > 0.01) {
      _currentZoomLevel = zoomLevel;
      _yoloController.setZoomLevel(zoomLevel);
      notifyListeners();
    }
  }

  void setLensFacing(LensFacing facing) {
    if (_isDisposed) return;

    if (_lensFacing != facing) {
      _lensFacing = facing;
      _isFrontCamera = facing == LensFacing.front;

      _yoloController.switchCamera();

      if (_isFrontCamera) {
        _currentZoomLevel = 1.0;
      }

      notifyListeners();
    }
  }

  void changeModel(ModelType model) {
    if (_isDisposed) return;

    if (!_isModelLoading && model != _selectedModel) {
      final previousModel = _selectedModel;
      _selectedModel = model;

      if (_modelPath != null && !_isFirstModelLoad) {
        _switchModelHotSwap(previousModel);
      } else {
        _loadModelForPlatform();
      }
    }
  }

  Future<void> _switchModelHotSwap(ModelType previousModel) async {
    if (_isDisposed) return;

    _isModelLoading = true;
    _loadingMessage = 'Switching to ${_selectedModel.displayName}...';
    _detectionCount = 0;
    _currentFps = 0.0;
    notifyListeners();

    try {
      final modelPath = await _modelManager.getModelPath(_selectedModel);

      if (_isDisposed) return;

      if (modelPath == null) {
        throw Exception('Failed to load ${_selectedModel.modelName} model');
      }

      await _yoloController.switchModel(modelPath, _selectedModel.task);

      _modelPath = modelPath;
      _isModelLoading = false;
      _loadingMessage = '';
      notifyListeners();
    } catch (e) {
      if (_isDisposed) return;

      _selectedModel = previousModel;
      _isModelLoading = false;
      _loadingMessage = 'Failed to switch model: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> _loadModelForPlatform() async {
    if (_isDisposed) return;

    if (_loadingFuture != null) {
      await _loadingFuture;
      return;
    }

    _loadingFuture = _performModelLoading();
    try {
      await _loadingFuture;
    } finally {
      _loadingFuture = null;
    }
  }

  Future<void> _performModelLoading() async {
    if (_isDisposed) return;

    _isModelLoading = true;
    _loadingMessage = 'Loading ${_selectedModel.modelName} model...';
    _downloadProgress = 0.0;
    _detectionCount = 0;
    _currentFps = 0.0;
    notifyListeners();

    try {
      final modelPath = await _modelManager.getModelPath(_selectedModel);

      if (_isDisposed) return;

      _modelPath = modelPath;
      _isModelLoading = false;
      _isFirstModelLoad = false; // Mark that first model is loaded
      _loadingMessage = '';
      _downloadProgress = 0.0;
      notifyListeners();

      if (modelPath == null) {
        throw Exception('Failed to load ${_selectedModel.modelName} model');
      }
    } catch (e) {
      if (_isDisposed) return;

      final error = YOLOErrorHandler.handleError(
        e,
        'Failed to load model ${_selectedModel.modelName} for task ${_selectedModel.task.name}',
      );

      _isModelLoading = false;
      _loadingMessage = 'Failed to load model: ${error.message}';
      _downloadProgress = 0.0;
      notifyListeners();
      rethrow;
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
