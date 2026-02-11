import 'package:flutter/material.dart';
import 'package:ultralytics_yolo_example/core/core.dart';
import 'package:ultralytics_yolo_example/features/evaluations/presentation/widgets/image_picker_sheet.dart';
import 'package:ultralytics_yolo_example/shared/widgets/image_nav_arrow.dart';

/// Multi-image navigation bar for the crop gallery.
/// Compact design that scales to 50+ images with prev/next arrows
/// and a tappable center that opens an image picker sheet.
class CropImageNavBar extends StatelessWidget {
  const CropImageNavBar({
    super.key,
    required this.imageCount,
    required this.currentIndex,
    this.onGoToImage,
  });

  final int imageCount;
  final int currentIndex;
  final void Function(int)? onGoToImage;

  @override
  Widget build(BuildContext context) {
    final hasPrev = currentIndex > 0;
    final hasNext = currentIndex < imageCount - 1;

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
            onTap: hasPrev ? () => onGoToImage?.call(currentIndex - 1) : null,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: GestureDetector(
              onTap: () => _showImagePicker(context),
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
                      Icons.photo_library_rounded,
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
            onTap: hasNext ? () => onGoToImage?.call(currentIndex + 1) : null,
          ),
        ],
      ),
    );
  }

  void _showImagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return ImagePickerSheet(
          imageCount: imageCount,
          currentIndex: currentIndex,
          onSelect: (i) {
            Navigator.pop(ctx);
            onGoToImage?.call(i);
          },
        );
      },
    );
  }
}
