import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:ultralytics_yolo_example/core/core.dart';
import 'package:ultralytics_yolo_example/features/evaluations/domain/models/models.dart';
import 'package:ultralytics_yolo_example/features/evaluations/presentation/widgets/crop_results_list.dart';
import 'package:ultralytics_yolo_example/features/evaluations/presentation/widgets/global_stats_section.dart';
import 'package:ultralytics_yolo_example/features/evaluations/presentation/widgets/result_image_nav_bar.dart';
import 'package:ultralytics_yolo_example/features/evaluations/presentation/widgets/stats_section.dart';
import 'package:ultralytics_yolo_example/shared/widgets/section_header.dart' show ContentSectionHeader;

/// Widget for displaying classification results with multi-image navigation
class ClassificationResultView extends StatelessWidget {
  const ClassificationResultView({
    super.key,
    required this.imageEvaluations,
    required this.currentImageIndex,
    required this.onImageChanged,
    required this.globalStats,
    required this.globalAvgConfidence,
    required this.onBack,
    required this.onSave,
    required this.onDownloadAll,
  });

  final List<ImageEvaluation> imageEvaluations;
  final int currentImageIndex;
  final void Function(int) onImageChanged;
  final Map<String, int> globalStats;
  final double globalAvgConfidence;
  final VoidCallback onBack;
  final VoidCallback onSave;
  final VoidCallback onDownloadAll;

  @override
  Widget build(BuildContext context) {
    if (imageEvaluations.isEmpty) {
      return Center(
        child: Text(
          'No hay resultados',
          style: TextStyle(color: context.textSecondaryColor),
        ),
      );
    }

    final safeIndex = currentImageIndex.clamp(0, imageEvaluations.length - 1);
    final currentEval = imageEvaluations[safeIndex];
    final hasMultipleImages = imageEvaluations.length > 1;

    return Column(
      children: [
        if (hasMultipleImages)
          ResultImageNavBar(
            imageCount: imageEvaluations.length,
            currentIndex: safeIndex,
            onGoToImage: onImageChanged,
            imageEvaluations: imageEvaluations,
          ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (currentEval.annotatedImage != null)
                  _AnnotatedImageCard(
                    imageBytes: currentEval.annotatedImage!,
                    onSave: onSave,
                    imageLabel: hasMultipleImages
                        ? 'Foto ${safeIndex + 1} de ${imageEvaluations.length}'
                        : null,
                  ),
                const SizedBox(height: 24),
                StatsSection(
                  stats: currentEval.getClassificationStats(),
                  averageConfidence: currentEval.getAverageConfidence(),
                  totalCrops: currentEval.selectedCount,
                ),
                if (hasMultipleImages) ...[
                  const SizedBox(height: 24),
                  GlobalStatsSection(
                    globalStats: globalStats,
                    globalAvgConfidence: globalAvgConfidence,
                    totalImages: imageEvaluations.length,
                    totalCrops: imageEvaluations.fold<int>(
                        0, (sum, e) => sum + e.selectedCount),
                  ),
                ],
                const SizedBox(height: 24),
                CropResultsList(crops: currentEval.selectedCrops),
              ],
            ),
          ),
        ),
        _ActionButtons(onBack: onBack, onDownloadAll: onDownloadAll),
      ],
    );
  }
}

/// Annotated image card with zoom
class _AnnotatedImageCard extends StatelessWidget {
  const _AnnotatedImageCard({
    required this.imageBytes,
    required this.onSave,
    this.imageLabel,
  });

  final Uint8List imageBytes;
  final VoidCallback onSave;
  final String? imageLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ContentSectionHeader(
          title: 'Imagen Anotada',
          color: AppColors.accent,
          trailing: imageLabel != null
              ? Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    imageLabel!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                )
              : null,
        ),
        const SizedBox(height: 12),
        AnnotatedImageViewer(
          imageBytes: imageBytes,
          fileName: 'clasificacion_${DateTime.now().millisecondsSinceEpoch}',
          borderRadius: 16,
        ),
      ],
    );
  }
}

/// Action buttons at the bottom
class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.onBack,
    required this.onDownloadAll,
  });

  final VoidCallback onBack;
  final VoidCallback onDownloadAll;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onBack,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: const BorderSide(color: AppColors.border),
                ),
                icon: const Icon(Icons.arrow_back),
                label: const Text(
                  'Volver a Recortes',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onDownloadAll,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.download_rounded),
                label: const Text(
                  'Descargar Todo',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
