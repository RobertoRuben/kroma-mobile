import 'package:flutter/foundation.dart';
import 'package:ultralytics_yolo_example/core/services/model_preloader.dart';
import 'package:ultralytics_yolo_example/features/evaluations/data/evaluation_repository.dart';
import 'package:ultralytics_yolo_example/features/evaluations/domain/models/models.dart';
import 'package:ultralytics_yolo_example/shared/controllers/settings_controller.dart';

/// Controller for managing the multi-image evaluation workflow
/// Flow: add image(s) → review crops per image → finalize → show results per image
class EvaluationController extends ChangeNotifier {
  EvaluationController({
    EvaluationRepository? repository,
  }) : _repository = repository ?? EvaluationRepository();

  final EvaluationRepository _repository;

  // State
  EvaluationState _state = EvaluationState.loading;
  String _statusMessage = '';
  String? _errorMessage;
  bool _isDisposed = false;

  // Multi-image data
  final List<ImageEvaluation> _imageEvaluations = [];
  int _currentImageIndex = 0;
  int _resultImageIndex = 0;

  // Getters
  EvaluationState get state => _state;
  String get statusMessage => _statusMessage;
  String? get errorMessage => _errorMessage;

  /// All image evaluations
  List<ImageEvaluation> get imageEvaluations =>
      List.unmodifiable(_imageEvaluations);

  /// Current image being reviewed
  ImageEvaluation? get currentImageEval =>
      _imageEvaluations.isNotEmpty &&
              _currentImageIndex < _imageEvaluations.length
          ? _imageEvaluations[_currentImageIndex]
          : null;

  /// Current image index for review
  int get currentImageIndex => _currentImageIndex;

  /// Current image index for results view
  int get resultImageIndex => _resultImageIndex;

  /// Total images added
  int get imageCount => _imageEvaluations.length;

  /// Crops for the current image under review
  List<CropItem> get crops => currentImageEval?.crops ?? [];

  /// Selected crops count for current image
  int get selectedCount => currentImageEval?.selectedCount ?? 0;

  /// Total crops count for current image
  int get totalCount => currentImageEval?.totalCount ?? 0;

  /// Total selected crops across ALL images
  int get totalSelectedCropsAllImages =>
      _imageEvaluations.fold(0, (sum, img) => sum + img.selectedCount);

  /// Total crops across ALL images
  int get totalCropsAllImages =>
      _imageEvaluations.fold(0, (sum, img) => sum + img.totalCount);

  /// Annotated image for results view
  Uint8List? get annotatedImage {
    if (_imageEvaluations.isEmpty) return null;
    final idx = _resultImageIndex.clamp(0, _imageEvaluations.length - 1);
    return _imageEvaluations[idx].annotatedImage;
  }

  // ========== Image Processing ==========

  /// Process multiple images in batch without flicker between them
  Future<void> processMultipleImages(List<Uint8List> imageBytesList) async {
    if (_isDisposed || imageBytesList.isEmpty) return;

    for (int i = 0; i < imageBytesList.length; i++) {
      final isLast = i == imageBytesList.length - 1;
      await processImage(imageBytesList[i], transitionToReview: isLast);
      if (_isDisposed) return;
      // If error state was set (e.g. single image with no crops), stop batch
      if (_state == EvaluationState.error) return;
    }
  }

  /// Process a single image (add to the list of evaluations)
  ///
  /// When [transitionToReview] is false, the state stays in processing mode
  /// after adding the image. Used for batch processing to avoid screen flicker.
  Future<void> processImage(
    Uint8List imageBytes, {
    bool transitionToReview = true,
  }) async {
    if (_isDisposed) return;

    try {
      // Wait for models to finish loading if a reload is in progress
      final preloader = ModelPreloader.instance;
      if (preloader.isLoading) {
        _updateState(EvaluationState.detecting, 'Esperando carga de modelo...');
        while (preloader.isLoading) {
          await Future.delayed(const Duration(milliseconds: 200));
          if (_isDisposed) return;
        }
      }

      // Run detection with threshold from global settings
      final imgIndex = _imageEvaluations.length + 1;
      _updateState(
        EvaluationState.detecting,
        'Detectando objetos en imagen $imgIndex...',
      );
      final threshold = SettingsController.instance.confidenceThreshold;
      final result = await _repository.detectAndExtractCrops(
        imageBytes,
        confidenceThreshold: threshold,
        onCropExtracted: (extracted, total) {
          if (_isDisposed) return;
          _updateState(
            EvaluationState.extractingCrops,
            'Imagen $imgIndex: extrayendo recorte $extracted de $total...',
          );
        },
      );

      if (_isDisposed) return;

      if (result.crops.isEmpty) {
        // If we already have images, just skip this one silently in batch
        if (_imageEvaluations.isNotEmpty) {
          if (transitionToReview) {
            _errorMessage = 'No se detectaron objetos en esta imagen';
            _updateState(
                EvaluationState.reviewingCrops, 'Revisión de detecciones');
          }
          return;
        }
        _updateState(EvaluationState.error, 'No se detectaron objetos');
        _errorMessage = 'No se encontraron objetos en la imagen';
        return;
      }

      // Make crop IDs unique across images
      final imageId = 'img_${_imageEvaluations.length}';
      final uniqueCrops = result.crops.asMap().entries.map((e) {
        return e.value.copyWith(id: '${imageId}_crop_${e.key}');
      }).toList();

      // Add this image evaluation
      _imageEvaluations.add(ImageEvaluation(
        id: imageId,
        originalImage: result.originalImage,
        imageWidth: result.imageWidth,
        imageHeight: result.imageHeight,
        crops: uniqueCrops,
      ));

      // Only transition to review when requested (last image in batch)
      if (transitionToReview) {
        _currentImageIndex = _imageEvaluations.length - 1;
        _updateState(EvaluationState.reviewingCrops, 'Revisión de detecciones');
      }
    } catch (e) {
      if (_isDisposed) return;
      debugPrint('Error processing image: $e');
      _updateState(EvaluationState.error, 'Error');
      _errorMessage = e.toString();
    }
  }

  // ========== Crop Selection ==========

  /// Toggle selection of a crop in the current image
  void toggleCropSelection(String cropId) {
    if (_isDisposed || currentImageEval == null) return;

    final crops = currentImageEval!.crops;
    final index = crops.indexWhere((c) => c.id == cropId);
    if (index != -1) {
      crops[index] = crops[index].copyWith(
        isSelected: !crops[index].isSelected,
      );
      notifyListeners();
    }
  }

  /// Select all crops in current image
  void selectAllCrops() {
    if (_isDisposed || currentImageEval == null) return;
    currentImageEval!.crops = currentImageEval!.crops
        .map((c) => c.copyWith(isSelected: true))
        .toList();
    notifyListeners();
  }

  /// Deselect all crops in current image
  void deselectAllCrops() {
    if (_isDisposed || currentImageEval == null) return;
    currentImageEval!.crops = currentImageEval!.crops
        .map((c) => c.copyWith(isSelected: false))
        .toList();
    notifyListeners();
  }

  // ========== Multi-image Navigation (review) ==========

  /// Navigate to a specific image for crop review
  void goToImage(int index) {
    if (index >= 0 && index < _imageEvaluations.length) {
      _currentImageIndex = index;
      notifyListeners();
    }
  }

  // ========== Finalize & Classify ==========

  /// Classify all selected crops across all images and generate annotated images
  Future<void> classifyAllImages() async {
    if (_isDisposed) return;

    if (totalSelectedCropsAllImages == 0) {
      _errorMessage = 'Selecciona al menos un recorte';
      notifyListeners();
      return;
    }

    try {
      final totalSelected = totalSelectedCropsAllImages;
      _updateState(
        EvaluationState.classifying,
        'Clasificando $totalSelected recortes...',
      );

      int classified = 0;

      // Classify crops for each image
      for (int i = 0; i < _imageEvaluations.length; i++) {
        final imgEval = _imageEvaluations[i];

        imgEval.crops = await _repository.classifyCrops(imgEval.crops);

        classified += imgEval.selectedCount;
        if (_isDisposed) return;

        _updateState(
          EvaluationState.classifying,
          'Clasificados $classified de $totalSelected recortes...',
        );
      }

      if (_isDisposed) return;

      // Generate annotated images for each image
      for (int i = 0; i < _imageEvaluations.length; i++) {
        final imgEval = _imageEvaluations[i];
        _updateState(
          EvaluationState.classifying,
          'Generando imagen anotada ${i + 1} de ${_imageEvaluations.length}...',
        );

        imgEval.annotatedImage = await _repository.generateAnnotatedImage(
          originalImage: imgEval.originalImage,
          crops: imgEval.crops,
          imageWidth: imgEval.imageWidth,
          imageHeight: imgEval.imageHeight,
        );

        if (_isDisposed) return;
      }

      _resultImageIndex = 0;
      _updateState(EvaluationState.showingResults, 'Resultados');
    } catch (e, stackTrace) {
      debugPrint('Classification error: $e');
      debugPrint('Stack trace: $stackTrace');
      if (_isDisposed) return;
      _updateState(EvaluationState.error, 'Error');
      _errorMessage = e.toString();
    }
  }

  // ========== Results Navigation ==========

  /// Navigate to results for a specific image
  void goToResultImage(int index) {
    if (index >= 0 && index < _imageEvaluations.length) {
      _resultImageIndex = index;
      notifyListeners();
    }
  }

  /// Global stats across all images
  Map<String, int> getGlobalClassificationStats() {
    final stats = <String, int>{};
    for (final imgEval in _imageEvaluations) {
      for (final crop in imgEval.selectedCrops) {
        final label =
            crop.classificationResult?.className ?? 'Sin clasificar';
        stats[label] = (stats[label] ?? 0) + 1;
      }
    }
    return stats;
  }

  /// Global average confidence
  double getGlobalAverageConfidence() {
    final allClassified = _imageEvaluations
        .expand((img) => img.selectedCrops)
        .where((c) => c.classificationResult != null)
        .toList();
    if (allClassified.isEmpty) return 0;
    final total = allClassified.fold<double>(
      0,
      (sum, c) => sum + (c.classificationResult?.confidence ?? 0),
    );
    return total / allClassified.length;
  }

  // ========== State Management ==========

  /// Go back to crop review from results
  void backToCropReview() {
    if (_isDisposed) return;
    _currentImageIndex = 0;
    // Clear annotated images so they get regenerated on next finalize
    for (final imgEval in _imageEvaluations) {
      imgEval.annotatedImage = null;
    }
    _updateState(EvaluationState.reviewingCrops, 'Revisión de detecciones');
  }

  /// Update state and notify listeners
  void _updateState(EvaluationState newState, String message) {
    if (_isDisposed) return;
    _state = newState;
    _statusMessage = message;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _repository.dispose();
    super.dispose();
  }
}
