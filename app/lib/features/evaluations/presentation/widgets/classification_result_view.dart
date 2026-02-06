import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:ultralytics_yolo_example/core/core.dart';
import 'package:ultralytics_yolo_example/features/evaluations/domain/models/models.dart';

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
  });

  final List<ImageEvaluation> imageEvaluations;
  final int currentImageIndex;
  final void Function(int) onImageChanged;
  final Map<String, int> globalStats;
  final double globalAvgConfidence;
  final VoidCallback onBack;
  final VoidCallback onSave;

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
        // Image navigation tabs (only when multiple images)
        if (hasMultipleImages)
          _ResultImageNavBar(
            imageCount: imageEvaluations.length,
            currentIndex: safeIndex,
            onGoToImage: onImageChanged,
            imageEvaluations: imageEvaluations,
          ),
        // Results content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Annotated image for current photo
                if (currentEval.annotatedImage != null)
                  _ImageCard(
                    imageBytes: currentEval.annotatedImage!,
                    onSave: onSave,
                    imageLabel: hasMultipleImages
                        ? 'Foto ${safeIndex + 1} de ${imageEvaluations.length}'
                        : null,
                  ),
                const SizedBox(height: 24),
                // Per-image stats
                _StatsSection(
                  stats: currentEval.getClassificationStats(),
                  averageConfidence: currentEval.getAverageConfidence(),
                  totalCrops: currentEval.selectedCount,
                ),
                // Global stats summary (only show when multiple images)
                if (hasMultipleImages) ...[
                  const SizedBox(height: 24),
                  _GlobalStatsSection(
                    globalStats: globalStats,
                    globalAvgConfidence: globalAvgConfidence,
                    totalImages: imageEvaluations.length,
                    totalCrops: imageEvaluations.fold<int>(
                        0, (sum, e) => sum + e.selectedCount),
                  ),
                ],
                const SizedBox(height: 24),
                _CropResultsList(
                  crops: currentEval.selectedCrops,
                ),
              ],
            ),
          ),
        ),
        _ActionButtons(onBack: onBack),
      ],
    );
  }
}

/// Navigation bar for browsing between image results — scales to 50+ images
class _ResultImageNavBar extends StatelessWidget {
  const _ResultImageNavBar({
    required this.imageCount,
    required this.currentIndex,
    required this.onGoToImage,
    required this.imageEvaluations,
  });

  final int imageCount;
  final int currentIndex;
  final void Function(int) onGoToImage;
  final List<ImageEvaluation> imageEvaluations;

  @override
  Widget build(BuildContext context) {
    final hasPrev = currentIndex > 0;
    final hasNext = currentIndex < imageCount - 1;
    final eval = imageEvaluations[currentIndex];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: context.cardColor,
        border: Border(
          bottom: BorderSide(color: context.borderSubtleColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Previous
          _ResultNavArrow(
            icon: Icons.chevron_left_rounded,
            enabled: hasPrev,
            onTap: hasPrev ? () => onGoToImage(currentIndex - 1) : null,
          ),
          const SizedBox(width: 4),
          // Central indicator with crop count
          Expanded(
            child: GestureDetector(
              onTap: () => _showResultImagePicker(context),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.image_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Foto ${currentIndex + 1} de $imageCount',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${eval.selectedCount} crops',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.unfold_more_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Next
          _ResultNavArrow(
            icon: Icons.chevron_right_rounded,
            enabled: hasNext,
            onTap: hasNext ? () => onGoToImage(currentIndex + 1) : null,
          ),
        ],
      ),
    );
  }

  void _showResultImagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return _ResultPickerSheet(
          imageEvaluations: imageEvaluations,
          currentIndex: currentIndex,
          onSelect: (i) {
            Navigator.pop(ctx);
            onGoToImage(i);
          },
        );
      },
    );
  }
}

/// Arrow button for result image navigation
class _ResultNavArrow extends StatelessWidget {
  const _ResultNavArrow({
    required this.icon,
    required this.enabled,
    this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled
          ? AppColors.primary.withValues(alpha: 0.1)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            size: 22,
            color: enabled
                ? AppColors.primary
                : context.textSecondaryColor.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet list for jumping to any result image
class _ResultPickerSheet extends StatelessWidget {
  const _ResultPickerSheet({
    required this.imageEvaluations,
    required this.currentIndex,
    required this.onSelect,
  });

  final List<ImageEvaluation> imageEvaluations;
  final int currentIndex;
  final void Function(int) onSelect;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: context.borderSubtleColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.image_rounded,
                    size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Resultados por imagen (${imageEvaluations.length})',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimaryColor,
                  ),
                ),
              ],
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.45,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              itemCount: imageEvaluations.length,
              itemBuilder: (context, i) {
                final eval = imageEvaluations[i];
                final isActive = i == currentIndex;
                final stats = eval.getClassificationStats();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Material(
                    color: isActive
                        ? AppColors.primary
                        : AppColors.primary.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () => onSelect(i),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isActive
                                    ? Colors.white.withValues(alpha: 0.2)
                                    : AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  '${i + 1}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: isActive
                                        ? Colors.white
                                        : AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Foto ${i + 1}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isActive
                                          ? Colors.white
                                          : context.textPrimaryColor,
                                    ),
                                  ),
                                  Text(
                                    '${eval.selectedCount} recortes · ${stats.entries.map((e) => '${e.key}: ${e.value}').join(', ')}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isActive
                                          ? Colors.white
                                              .withValues(alpha: 0.7)
                                          : context.textSecondaryColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            if (isActive)
                              const Icon(Icons.check_circle_rounded,
                                  size: 18, color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Global stats summary across all images
class _GlobalStatsSection extends StatelessWidget {
  const _GlobalStatsSection({
    required this.globalStats,
    required this.globalAvgConfidence,
    required this.totalImages,
    required this.totalCrops,
  });

  final Map<String, int> globalStats;
  final double globalAvgConfidence;
  final int totalImages;
  final int totalCrops;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.06),
            AppColors.accent.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.assessment_rounded,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Resumen Global',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _MiniStat(
                  label: 'Fotos',
                  value: '$totalImages',
                  icon: Icons.photo_library_rounded),
              const SizedBox(width: 16),
              _MiniStat(
                  label: 'Recortes',
                  value: '$totalCrops',
                  icon: Icons.crop_rounded),
              const SizedBox(width: 16),
              _MiniStat(
                  label: 'Confianza',
                  value: '${(globalAvgConfidence * 100).toStringAsFixed(0)}%',
                  icon: Icons.analytics_rounded),
            ],
          ),
          if (globalStats.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: globalStats.entries.map((entry) {
                return Chip(
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  label: Text(
                    '${entry.key}: ${entry.value}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor:
                      AppColors.primary.withValues(alpha: 0.1),
                  side: BorderSide.none,
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

/// Mini stat for global summary
class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: context.textSecondaryColor),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: context.textPrimaryColor,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: context.textSecondaryColor,
          ),
        ),
      ],
    );
  }
}

/// Annotated image card with zoom
class _ImageCard extends StatelessWidget {
  const _ImageCard({
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
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Imagen Anotada',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: context.textPrimaryColor,
                letterSpacing: -0.3,
              ),
            ),
            if (imageLabel != null) ...[
              const Spacer(),
              Container(
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
              ),
            ],
          ],
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

/// Statistics section
class _StatsSection extends StatelessWidget {
  const _StatsSection({
    required this.stats,
    required this.averageConfidence,
    required this.totalCrops,
  });

  final Map<String, int> stats;
  final double averageConfidence;
  final int totalCrops;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Resumen de Clasificación',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: context.textPrimaryColor,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Summary cards
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Total Clasificados',
                value: '$totalCrops',
                icon: Icons.check_circle_outline,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Confianza Prom.',
                value: '${(averageConfidence * 100).toStringAsFixed(0)}%',
                icon: Icons.analytics_outlined,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Classification breakdown
        if (stats.isNotEmpty) ...[
          Text(
            'Distribución por Clase',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: context.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 8),
          ...stats.entries.map(
            (entry) => _ClassBreakdownItem(
              className: entry.key,
              count: entry.value,
              total: totalCrops,
            ),
          ),
        ],
      ],
    );
  }
}

/// Individual stat card
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderSubtleColor),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: color.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: context.textPrimaryColor,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: context.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Class breakdown item
class _ClassBreakdownItem extends StatelessWidget {
  const _ClassBreakdownItem({
    required this.className,
    required this.count,
    required this.total,
  });

  final String className;
  final int count;
  final int total;

  @override
  Widget build(BuildContext context) {
    final percentage = total > 0 ? count / total : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              className,
              style: TextStyle(
                fontSize: 14,
                color: context.textPrimaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: percentage,
                backgroundColor: context.borderSubtleColor,
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 50,
            child: Text(
              '$count (${(percentage * 100).toStringAsFixed(0)}%)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: context.textSecondaryColor,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

/// List of crop results with classifications
class _CropResultsList extends StatelessWidget {
  const _CropResultsList({required this.crops});

  final List<CropItem> crops;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Detalle de Clasificaciones',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: context.textPrimaryColor,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: crops.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            return _CropResultItem(crop: crops[index], index: index);
          },
        ),
      ],
    );
  }
}

/// Individual crop result item
class _CropResultItem extends StatelessWidget {
  const _CropResultItem({
    required this.crop,
    required this.index,
  });

  final CropItem crop;
  final int index;

  @override
  Widget build(BuildContext context) {
    final result = crop.classificationResult;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderSubtleColor),
      ),
      child: Row(
        children: [
          // Crop thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.memory(
              crop.imageBytes,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          // Classification info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result?.className ?? 'Sin clasificar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Confianza: ${((result?.confidence ?? 0) * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 13,
                    color: context.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          // Index badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '#${index + 1}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Action buttons at the bottom
class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.onBack});

  final VoidCallback onBack;

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
          ],
        ),
      ),
    );
  }
}
