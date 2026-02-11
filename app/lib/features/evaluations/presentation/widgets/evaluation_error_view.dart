import 'package:flutter/material.dart';
import 'package:ultralytics_yolo_example/core/core.dart';

/// Error view with a message and retry/back button.
class EvaluationErrorView extends StatelessWidget {
  const EvaluationErrorView({
    super.key,
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
              style: TextStyle(fontSize: 14, color: context.textSecondaryColor),
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
