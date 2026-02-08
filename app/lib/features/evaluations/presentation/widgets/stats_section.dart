import 'package:flutter/material.dart';
import 'package:ultralytics_yolo_example/core/core.dart';
import 'package:ultralytics_yolo_example/features/evaluations/domain/models/crop_item.dart';
import 'package:ultralytics_yolo_example/shared/widgets/section_header.dart' show ContentSectionHeader;

/// Statistics section showing classification summary and breakdown
class StatsSection extends StatelessWidget {
  const StatsSection({
    super.key,
    required this.stats,
    required this.averageConfidence,
    required this.totalCrops,
  });

  final Map<String, int> stats;
  final double averageConfidence;
  final int totalCrops;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ContentSectionHeader(title: 'Resumen de Clasificación'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Total Clasificados',
                value: '$totalCrops',
                icon: Icons.check_circle_outline,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Confianza Prom.',
                value: '${(averageConfidence * 100).toStringAsFixed(0)}%',
                icon: Icons.analytics_outlined,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (stats.isNotEmpty) ...[
          Text(
            'Distribución por Clase',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: context.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 8),
          ...stats.entries.map(
            (entry) => ClassBreakdownItem(
              className: entry.key,
              count: entry.value,
              total: totalCrops,
            ),
          ),
        ],
      ],
    );
  }
}

/// Individual stat card
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderSubtleColor),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: color.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: context.textPrimaryColor,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            title,
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

/// Class breakdown item with progress bar
class ClassBreakdownItem extends StatelessWidget {
  const ClassBreakdownItem({
    super.key,
    required this.className,
    required this.count,
    required this.total,
  });

  final String className;
  final int count;
  final int total;

  @override
  Widget build(BuildContext context) {
    final percentage = total > 0 ? count / total : 0.0;
    final barColor = ClassificationResult.maturityColorFor(className);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: barColor,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              className,
              style: TextStyle(
                fontSize: 14,
                color: context.textPrimaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: percentage,
                backgroundColor: context.borderSubtleColor,
                valueColor: AlwaysStoppedAnimation(barColor),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 50,
            child: Text(
              '$count (${(percentage * 100).toStringAsFixed(0)}%)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: context.textSecondaryColor,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
