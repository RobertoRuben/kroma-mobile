// Ultralytics 🚀 AGPL-3.0 License - https://ultralytics.com/license

import 'package:flutter/material.dart';
import 'package:ultralytics_yolo_example/core/core.dart';
import 'package:ultralytics_yolo_example/shared/models/models.dart';

/// Simplified stats overlay showing detection count, FPS, and model info
class DetectionStatsOverlay extends StatelessWidget {
  const DetectionStatsOverlay({
    super.key,
    required this.detectionCount,
    required this.fps,
    required this.selectedModel,
    required this.onStop,
  });

  final int detectionCount;
  final double fps;
  final ModelType selectedModel;
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
          // Model label at top
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  selectedModel.isDetector ? Icons.search : Icons.category,
                  color: AppColors.primary,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  selectedModel.displayName,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Stats row
          Row(
            children: [
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
          // Stop button
          GestureDetector(
            onTap: onStop,
            child: Container(
              width: double.infinity,
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
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
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
