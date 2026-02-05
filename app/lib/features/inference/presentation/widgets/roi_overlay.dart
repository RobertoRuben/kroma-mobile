// Ultralytics 🚀 AGPL-3.0 License - https://ultralytics.com/license

import 'package:flutter/material.dart';
import 'package:ultralytics_yolo_example/core/core.dart';

/// Widget that displays a counting line overlay with stats
///
/// Shows a horizontal line where objects are counted when they cross it
/// Layer that displays the static ROI lines and labels
class ROILines extends StatelessWidget {
  const ROILines({
    super.key,
    required this.roiTopPercent,
    required this.roiBottomPercent,
  });

  /// Top of tolerance zone (line position - tolerance)
  final double roiTopPercent;

  /// Bottom of tolerance zone (line position + tolerance)
  final double roiBottomPercent;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalHeight = constraints.maxHeight;
        // Line is in the middle of the tolerance zone
        final lineY = totalHeight * (roiTopPercent + roiBottomPercent) / 2;

        return Stack(
          children: [
            // Main counting line (solid, thick) - Using primary color
            Positioned(
              top: lineY - 2,
              left: 0,
              right: 0,
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.3),
                      AppColors.primary,
                      AppColors.primary,
                      AppColors.primary.withValues(alpha: 0.3),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),

            // Arrow indicators on the line
            Positioned(
              top: lineY - 18,
              left: 24,
              child: _buildArrowIndicator(),
            ),
            Positioned(
              top: lineY - 18,
              right: 24,
              child: _buildArrowIndicator(),
            ),

            // "LÍNEA DE CONTEO" label below line
            Positioned(
              top: lineY + 10,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                  ),
                  child: const Text(
                    'LÍNEA DE CONTEO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildArrowIndicator() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.arrow_downward, color: Colors.white, size: 16),
    );
  }
}

/// Widget that displays the stats panel (Count, FPS, Controls)
class ROIStats extends StatelessWidget {
  const ROIStats({
    super.key,
    required this.count,
    required this.detectionCount,
    required this.fps,
    required this.onReset,
    required this.onStop,
  });

  final int count;
  final int detectionCount;
  final double fps;
  final VoidCallback onReset;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Stats row
          Row(
            children: [
              // Count
              Expanded(
                child: _buildStatItem(
                  icon: Icons.eco,
                  label: 'Contados',
                  value: '$count',
                  color: AppColors.primary,
                  isLarge: true,
                ),
              ),
              // Divider
              Container(height: 50, width: 1, color: Colors.white24),
              // Detections
              Expanded(
                child: _buildStatItem(
                  icon: Icons.visibility,
                  label: 'Detectados',
                  value: '$detectionCount',
                  color: AppColors.accent,
                ),
              ),
              // Divider
              Container(height: 50, width: 1, color: Colors.white24),
              // FPS
              Expanded(
                child: _buildStatItem(
                  icon: Icons.speed,
                  label: 'FPS',
                  value: fps.toStringAsFixed(1),
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Buttons row
          Row(
            children: [
              // Reset button
              Expanded(
                child: GestureDetector(
                  onTap: onReset,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.refresh,
                          color: AppColors.textPrimary,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Reiniciar',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Stop button
              Expanded(
                child: GestureDetector(
                  onTap: onStop,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.destructive,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.stop, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Detener',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool isLarge = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: isLarge ? 24 : 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: isLarge ? 28 : 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
      ],
    );
  }
}
