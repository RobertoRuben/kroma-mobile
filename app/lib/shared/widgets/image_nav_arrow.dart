import 'package:flutter/material.dart';
import 'package:ultralytics_yolo_example/core/core.dart';

/// Reusable arrow button for prev/next image navigation.
///
/// Used in both [CropGallery] and [ClassificationResultView] navigation bars.
class ImageNavArrow extends StatelessWidget {
  const ImageNavArrow({
    super.key,
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
