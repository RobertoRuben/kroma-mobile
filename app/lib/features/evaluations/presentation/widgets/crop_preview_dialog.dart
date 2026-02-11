import 'package:flutter/material.dart';
import 'package:ultralytics_yolo_example/core/core.dart';
import 'package:ultralytics_yolo_example/features/evaluations/domain/models/models.dart';

/// Preview dialog showing a crop enlarged with confidence and classification info.
class CropPreviewDialog extends StatelessWidget {
  const CropPreviewDialog({super.key, required this.crop});

  final CropItem crop;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.85,
              maxHeight: MediaQuery.of(context).size.height * 0.55,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          crop.imageBytes,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  _PreviewInfoBar(crop: crop),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewInfoBar extends StatelessWidget {
  const _PreviewInfoBar({required this.crop});

  final CropItem crop;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.background,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Conf: ${(crop.confidence * 100).toStringAsFixed(1)}%',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
          if (crop.classificationResult != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                crop.classificationResult!.className,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.accentLight : AppColors.accent,
                ),
              ),
            ),
          ],
          const Spacer(),
          Text(
            crop.id.replaceAll('crop_', '#'),
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
