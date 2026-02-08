import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ultralytics_yolo_example/core/core.dart';
import 'package:ultralytics_yolo_example/features/evaluations/domain/models/models.dart';
import 'package:ultralytics_yolo_example/features/evaluations/presentation/controllers/evaluation_controller.dart';
import 'package:ultralytics_yolo_example/features/evaluations/presentation/widgets/crop_gallery.dart';
import 'package:ultralytics_yolo_example/features/evaluations/presentation/widgets/classification_result_view.dart';

/// Screen for handling the complete multi-image evaluation workflow:
/// 1. Detection and crop extraction per image
/// 2. Crop review with option to add more photos
/// 3. Finalize → classification of all selected crops
/// 4. Results display per image
class EvaluationResultScreen extends StatefulWidget {
  const EvaluationResultScreen({
    super.key,
    required this.imageFiles,
    this.sourceIsCamera = false,
  });

  /// Initial image files to process
  final List<XFile> imageFiles;

  /// Whether the source is camera (allows taking more photos)
  final bool sourceIsCamera;

  @override
  State<EvaluationResultScreen> createState() => _EvaluationResultScreenState();
}

class _EvaluationResultScreenState extends State<EvaluationResultScreen> {
  late final EvaluationController _controller;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _controller = EvaluationController();
    _initializeEvaluation();
  }

  Future<void> _initializeEvaluation() async {
    // Read all image files first
    final allBytes = <Uint8List>[];
    for (final file in widget.imageFiles) {
      final imageBytes = await compute(_readFileBytes, file.path);
      if (!mounted) return;
      allBytes.add(imageBytes);
    }
    if (!mounted) return;
    // Process all in batch (no flicker between images)
    await _controller.processMultipleImages(allBytes);
  }

  /// Isolate-safe function to read file bytes off the main thread
  static Future<Uint8List> _readFileBytes(String path) async {
    final file = XFile(path);
    return await file.readAsBytes();
  }

  /// Add more photos from camera
  Future<void> _addFromCamera() async {
    try {
      final file = await _picker.pickImage(source: ImageSource.camera);
      if (file != null && mounted) {
        final imageBytes = await compute(_readFileBytes, file.path);
        if (mounted) {
          await _controller.processImage(imageBytes);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al capturar imagen: $e')),
        );
      }
    }
  }

  /// Add more photos from gallery
  Future<void> _addFromGallery() async {
    try {
      final files = await _picker.pickMultiImage();
      if (files.isNotEmpty && mounted) {
        final allBytes = <Uint8List>[];
        for (final file in files) {
          final imageBytes = await compute(_readFileBytes, file.path);
          if (!mounted) return;
          allBytes.add(imageBytes);
        }
        if (mounted && allBytes.isNotEmpty) {
          await _controller.processMultipleImages(allBytes);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar imágenes: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showSaveSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Imagen guardada en galería'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  bool _isDownloading = false;

  Future<void> _downloadAllAnnotatedImages() async {
    if (_isDownloading) return;

    final evaluations = _controller.imageEvaluations;
    final annotatedImages = evaluations
        .where((e) => e.annotatedImage != null)
        .toList();

    if (annotatedImages.isEmpty) return;

    setState(() => _isDownloading = true);

    try {
      final tempDir = await getTemporaryDirectory();
      int saved = 0;

      for (int i = 0; i < annotatedImages.length; i++) {
        final imgEval = annotatedImages[i];
        final name = 'kroma_anotada_${i + 1}_${DateTime.now().millisecondsSinceEpoch}';
        final filePath = '${tempDir.path}/$name.png';

        final file = File(filePath);
        await file.writeAsBytes(imgEval.annotatedImage!);
        await Gal.putImage(filePath, album: 'Kroma');

        if (await file.exists()) await file.delete();
        saved++;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$saved imagen${saved > 1 ? 'es' : ''} guardada${saved > 1 ? 's' : ''} en galería'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: AppColors.destructive,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: context.backgroundColor,
          appBar: CustomAppBar(
            title: 'Evaluación',
            subtitle: _controller.state == EvaluationState.showingResults
                ? 'Resultados'
                : _controller.state == EvaluationState.reviewingCrops
                    ? 'Foto ${_controller.currentImageIndex + 1} de ${_controller.imageCount}'
                    : _controller.statusMessage,
          ),
          body: _buildBody(),
        );
      },
    );
  }

  Widget _buildBody() {
    // Show processing dialog during async operations
    if (_controller.state.isProcessing) {
      return _ProcessingView(
        message: _controller.statusMessage,
      );
    }

    // Show error state
    if (_controller.state == EvaluationState.error) {
      return _ErrorView(
        message: _controller.errorMessage ?? 'Error desconocido',
        onRetry: () => Navigator.pop(context),
      );
    }

    // Show crop gallery for review
    if (_controller.state == EvaluationState.reviewingCrops) {
      return CropGallery(
        crops: _controller.crops,
        selectedCount: _controller.selectedCount,
        totalCount: _controller.totalCount,
        onToggleSelection: _controller.toggleCropSelection,
        onClassify: _controller.classifyAllImages,
        onSelectAll: _controller.selectAllCrops,
        onDeselectAll: _controller.deselectAllCrops,
        // Multi-image support
        imageCount: _controller.imageCount,
        currentImageIndex: _controller.currentImageIndex,
        onGoToImage: _controller.goToImage,
        onAddFromCamera: _addFromCamera,
        onAddFromGallery: _addFromGallery,
        totalSelectedAllImages: _controller.totalSelectedCropsAllImages,
      );
    }

    // Show final results (per image navigation)
    if (_controller.state == EvaluationState.showingResults) {
      return ClassificationResultView(
        imageEvaluations: _controller.imageEvaluations,
        currentImageIndex: _controller.resultImageIndex,
        onImageChanged: _controller.goToResultImage,
        globalStats: _controller.getGlobalClassificationStats(),
        globalAvgConfidence: _controller.getGlobalAverageConfidence(),
        onBack: _controller.backToCropReview,
        onSave: _showSaveSuccess,
        onDownloadAll: _downloadAllAnnotatedImages,
      );
    }

    // Fallback loading
    return const _ProcessingView(message: 'Cargando...');
  }
}

/// Processing view with spinner
class _ProcessingView extends StatelessWidget {
  const _ProcessingView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: context.borderSubtleColor),
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        blurRadius: 30,
                        offset: const Offset(0, 12),
                      ),
                    ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: context.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Error view with retry option
class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.destructive.withValues(alpha: 0.15)
                    : AppColors.destructiveLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: AppColors.destructive,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Ocurrió un error',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: context.textPrimaryColor,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: context.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text(
                'Volver',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
