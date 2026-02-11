import 'package:flutter/material.dart';
import 'package:ultralytics_yolo_example/core/core.dart';

/// Processing view with spinner and progress bar.
/// Shows batch progress when processing multiple images.
class ProcessingView extends StatelessWidget {
  const ProcessingView({
    super.key,
    required this.message,
    this.progress = 0.0,
    this.currentImage = 0,
    this.totalImages = 0,
  });

  final String message;
  final double progress;
  final int currentImage;
  final int totalImages;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final showProgress = totalImages > 1;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            margin: const EdgeInsets.symmetric(horizontal: 32),
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
                if (showProgress) ...[
                  const SizedBox(height: 20),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: context.borderSubtleColor,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$currentImage de $totalImages imágenes',
                    style: TextStyle(
                      fontSize: 13,
                      color: context.textSecondaryColor.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
