import 'package:flutter/foundation.dart';
import 'package:ultralytics_yolo/yolo.dart';
import 'package:ultralytics_yolo_example/features/inference/data/model_manager.dart';
import 'package:ultralytics_yolo_example/shared/models/models.dart';

/// Service for preloading and caching YOLO models
/// Models are loaded once at startup and reused throughout the app
class ModelPreloader extends ChangeNotifier {
  ModelPreloader._();
  static final ModelPreloader instance = ModelPreloader._();

  final ModelManager _modelManager = ModelManager();

  YOLO? _detector;
  YOLO? _classifier;
  ModelType _currentDetectorType = ModelType.detectorInt8;
  ModelType _currentClassifierType = ModelType.maturityFloat16;

  bool _isLoadingDetector = false;
  bool _isLoadingClassifier = false;
  String? _loadingMessage;
  String? _errorMessage;

  // Getters
  YOLO? get detector => _detector;
  YOLO? get classifier => _classifier;
  ModelType get currentDetectorType => _currentDetectorType;
  ModelType get currentClassifierType => _currentClassifierType;
  bool get isLoading => _isLoadingDetector || _isLoadingClassifier;
  bool get isLoadingDetector => _isLoadingDetector;
  bool get isLoadingClassifier => _isLoadingClassifier;
  String? get loadingMessage => _loadingMessage;
  String? get errorMessage => _errorMessage;
  bool get isDetectorReady => _detector?.isInitialized ?? false;
  bool get isClassifierReady => _classifier?.isInitialized ?? false;

  /// Initialize both models at app startup
  Future<void> initialize() async {
    // Load models sequentially to reduce peak memory/CPU and avoid ANR
    await loadDetector(_currentDetectorType);
    await loadClassifier(_currentClassifierType);
  }

  /// Load or switch detector model
  Future<bool> loadDetector(ModelType modelType) async {
    if (_isLoadingDetector) return false;
    if (_detector?.isInitialized == true && _currentDetectorType == modelType) {
      return true;
    }

    _isLoadingDetector = true;
    _loadingMessage = 'Cargando detector ${modelType.displayName}...';
    _errorMessage = null;
    notifyListeners();

    try {
      // Dispose previous detector
      if (_detector != null) {
        await _detector!.dispose();
        _detector = null;
      }

      final modelPath = await _modelManager.getModelPath(modelType);
      if (modelPath == null) {
        throw Exception('No se encontró el modelo detector');
      }

      // int8 models must run on CPU; float16/float32 leverage GPU acceleration
      final useGpu = modelType != ModelType.detectorInt8;
      debugPrint('Loading detector: $modelPath (GPU: $useGpu)');
      _detector = YOLO(
        modelPath: modelPath,
        task: YOLOTask.detect,
        useMultiInstance: true,
        useGpu: useGpu,
        numItemsThreshold: 100,
      );

      final success = await _detector!.loadModel();
      if (!success) {
        throw Exception('Falló la carga del detector');
      }

      _currentDetectorType = modelType;
      debugPrint('Detector loaded successfully: ${_detector!.instanceId}');

      _isLoadingDetector = false;
      _loadingMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error loading detector: $e');
      _errorMessage = e.toString();
      _isLoadingDetector = false;
      _loadingMessage = null;
      notifyListeners();
      return false;
    }
  }

  /// Load or switch classifier model
  Future<bool> loadClassifier(ModelType modelType) async {
    if (_isLoadingClassifier) return false;
    if (_classifier?.isInitialized == true && _currentClassifierType == modelType) {
      return true;
    }

    _isLoadingClassifier = true;
    _loadingMessage = 'Cargando clasificador ${modelType.displayName}...';
    _errorMessage = null;
    notifyListeners();

    try {
      // Dispose previous classifier
      if (_classifier != null) {
        await _classifier!.dispose();
        _classifier = null;
      }

      final modelPath = await _modelManager.getModelPath(modelType);
      if (modelPath == null) {
        throw Exception('No se encontró el modelo clasificador');
      }

      // Classifier models are always float16/float32, so always use GPU
      debugPrint('Loading classifier: $modelPath (GPU: true)');
      _classifier = YOLO(
        modelPath: modelPath,
        task: YOLOTask.classify,
        useMultiInstance: true,
        useGpu: true,
      );

      final success = await _classifier!.loadModel();
      if (!success) {
        throw Exception('Falló la carga del clasificador');
      }

      _currentClassifierType = modelType;
      debugPrint('Classifier loaded successfully: ${_classifier!.instanceId}');

      _isLoadingClassifier = false;
      _loadingMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error loading classifier: $e');
      _errorMessage = e.toString();
      _isLoadingClassifier = false;
      _loadingMessage = null;
      notifyListeners();
      return false;
    }
  }

  /// Dispose all models
  Future<void> disposeAll() async {
    if (_detector != null) {
      await _detector!.dispose();
      _detector = null;
    }
    if (_classifier != null) {
      await _classifier!.dispose();
      _classifier = null;
    }
  }
}
