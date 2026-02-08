import 'package:flutter/material.dart';
import 'package:ultralytics_yolo_example/core/core.dart';
import 'package:ultralytics_yolo_example/features/evaluations/domain/models/models.dart';
import 'package:ultralytics_yolo_example/shared/widgets/image_nav_arrow.dart';

/// Navigation bar for browsing between image results — scales to 50+ images
class ResultImageNavBar extends StatelessWidget {
  const ResultImageNavBar({
    super.key,
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
          ImageNavArrow(
            icon: Icons.chevron_left_rounded,
            enabled: hasPrev,
            onTap: hasPrev ? () => onGoToImage(currentIndex - 1) : null,
          ),
          const SizedBox(width: 4),
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
          ImageNavArrow(
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
        return ResultPickerSheet(
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

/// Bottom sheet list for jumping to any result image
class ResultPickerSheet extends StatelessWidget {
  const ResultPickerSheet({
    super.key,
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
                                    : AppColors.primary
                                        .withValues(alpha: 0.1),
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
