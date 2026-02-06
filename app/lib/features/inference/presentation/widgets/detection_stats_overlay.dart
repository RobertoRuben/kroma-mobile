// Ultralytics AGPL-3.0 License - https://ultralytics.com/license

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
    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ModelLabel(selectedModel: selectedModel),
              const SizedBox(height: 16),
              _StatsRow(
                detectionCount: detectionCount,
                fps: fps,
              ),
              const SizedBox(height: 16),
              _StopButton(onStop: onStop),
            ],
          ),
        ),
      ),
    );
  }
}

/// Model label widget
class _ModelLabel extends StatelessWidget {
  const _ModelLabel({required this.selectedModel});

  final ModelType selectedModel;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
    );
  }
}

/// Stats row with detection count and FPS
class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.detectionCount,
    required this.fps,
  });

  final int detectionCount;
  final double fps;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatItem(
            icon: Icons.visibility,
            label: 'Detectados',
            value: '$detectionCount',
            color: AppColors.accent,
          ),
        ),
        const _Divider(),
        Expanded(
          child: _StatItem(
            icon: Icons.speed,
            label: 'FPS',
            value: fps.toStringAsFixed(1),
            color: AppColors.success,
          ),
        ),
      ],
    );
  }
}

/// Vertical divider
class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 50,
      child: VerticalDivider(color: Colors.white24, width: 1),
    );
  }
}

/// Individual stat item
class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
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

/// Stop button
class _StopButton extends StatelessWidget {
  const _StopButton({required this.onStop});

  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.destructive,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onStop,
        borderRadius: BorderRadius.circular(12),
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 14),
          child: Row(
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
    );
  }
}
