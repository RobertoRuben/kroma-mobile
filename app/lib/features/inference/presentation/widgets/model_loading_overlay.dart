// Ultralytics 🚀 AGPL-3.0 License - https://ultralytics.com/license

import 'package:flutter/material.dart';
import 'package:ultralytics_yolo_example/core/core.dart';

/// A loading overlay widget that displays model loading progress
class ModelLoadingOverlay extends StatelessWidget {
  const ModelLoadingOverlay({
    super.key,
    required this.loadingMessage,
    required this.downloadProgress,
  });

  final String loadingMessage;
  final double downloadProgress;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    return Container(
      color: context.backgroundColor,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Loading animation
            // App Logo
            // App Logo
            ClipOval(
              child: Image.asset(
                isDark
                    ? 'lib/assets/app-logo-dark.png'
                    : 'lib/assets/app-logo.png',
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 36),
            // Progress indicator
            SizedBox(
              width: 220,
              child: Column(
                children: [
                  if (downloadProgress > 0)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: downloadProgress,
                        backgroundColor: isDark
                            ? AppColors.borderDark
                            : AppColors.secondary,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                        minHeight: 8,
                      ),
                    )
                  else
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  const SizedBox(height: 20),
                  Text(
                    loadingMessage.isNotEmpty
                        ? loadingMessage
                        : 'Cargando modelo...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: context.textSecondaryColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (downloadProgress > 0) ...[
                    const SizedBox(height: 10),
                    Text(
                      '${(downloadProgress * 100).toInt()}%',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
