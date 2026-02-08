import 'package:flutter/material.dart';
import 'package:ultralytics_yolo_example/core/core.dart';
import 'package:ultralytics_yolo_example/features/evaluations/domain/models/models.dart';
import 'package:ultralytics_yolo_example/shared/widgets/section_header.dart' show ContentSectionHeader;

/// List of crop results with classifications
class CropResultsList extends StatelessWidget {
  const CropResultsList({
    super.key,
    required this.crops,
  });

  final List<CropItem> crops;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ContentSectionHeader(
          title: 'Detalle de Clasificaciones',
          color: AppColors.accent,
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: crops.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            return CropResultItem(crop: crops[index], index: index);
          },
        ),
      ],
    );
  }
}

/// Individual crop result item
class CropResultItem extends StatelessWidget {
  const CropResultItem({
    super.key,
    required this.crop,
    required this.index,
  });

  final CropItem crop;
  final int index;

  @override
  Widget build(BuildContext context) {
    final result = crop.classificationResult;
    final confidencePercent =
        ((result?.confidence ?? 0) * 100).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderSubtleColor),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.memory(
              crop.imageBytes,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: result?.maturityColor ?? AppColors.textSecondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Text(
                      result?.className ?? 'Sin clasificar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Confianza: $confidencePercent%',
                  style: TextStyle(
                    fontSize: 13,
                    color: context.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '#${index + 1}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
