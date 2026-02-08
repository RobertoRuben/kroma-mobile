import 'package:flutter/material.dart';
import 'package:ultralytics_yolo_example/core/core.dart';
import 'package:ultralytics_yolo_example/features/evaluations/domain/models/crop_item.dart';

/// Global stats summary across all images
class GlobalStatsSection extends StatelessWidget {
  const GlobalStatsSection({
    super.key,
    required this.globalStats,
    required this.globalAvgConfidence,
    required this.totalImages,
    required this.totalCrops,
  });

  final Map<String, int> globalStats;
  final double globalAvgConfidence;
  final int totalImages;
  final int totalCrops;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.06),
            AppColors.accent.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.assessment_rounded,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Resumen Global',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _MiniStat(
                  label: 'Fotos',
                  value: '$totalImages',
                  icon: Icons.photo_library_rounded),
              const SizedBox(width: 16),
              _MiniStat(
                  label: 'Recortes',
                  value: '$totalCrops',
                  icon: Icons.crop_rounded),
              const SizedBox(width: 16),
              _MiniStat(
                  label: 'Confianza',
                  value: '${(globalAvgConfidence * 100).toStringAsFixed(0)}%',
                  icon: Icons.analytics_rounded),
            ],
          ),
          if (globalStats.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: globalStats.entries.map((entry) {
                final chipColor = ClassificationResult.maturityColorFor(entry.key);
                return Chip(
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  avatar: CircleAvatar(
                    backgroundColor: chipColor,
                    radius: 5,
                  ),
                  label: Text(
                    '${entry.key}: ${entry.value}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: chipColor.withValues(alpha: 0.1),
                  side: BorderSide.none,
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

/// Mini stat for global summary
class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: context.textSecondaryColor),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: context.textPrimaryColor,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: context.textSecondaryColor,
          ),
        ),
      ],
    );
  }
}
