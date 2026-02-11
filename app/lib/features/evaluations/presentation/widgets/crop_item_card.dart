import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:ultralytics_yolo_example/core/core.dart';
import 'package:ultralytics_yolo_example/features/evaluations/domain/models/models.dart';
import 'package:ultralytics_yolo_example/features/evaluations/presentation/widgets/crop_preview_dialog.dart';

/// Individual crop item card with selection indicator and preview button
class CropItemCard extends StatelessWidget {
  const CropItemCard({
    super.key,
    required this.crop,
    required this.onTap,
  });

  final CropItem crop;
  final VoidCallback onTap;

  void _showPreview(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => CropPreviewDialog(crop: crop),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: crop.isSelected ? AppColors.primary : context.borderColor,
            width: crop.isSelected ? 2.5 : 1,
          ),
          boxShadow: crop.isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _CropImage(isSelected: crop.isSelected, imageBytes: crop.imageBytes),
              _SelectionIndicator(isSelected: crop.isSelected),
              _PreviewButton(onTap: () => _showPreview(context)),
              _ConfidenceBadge(confidence: crop.confidence),
              if (crop.classificationResult != null)
                _ClassificationBadge(
                  className: crop.classificationResult!.className,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CropImage extends StatelessWidget {
  const _CropImage({
    required this.isSelected,
    required this.imageBytes,
  });

  final bool isSelected;
  final Uint8List imageBytes;

  @override
  Widget build(BuildContext context) {
    return ColorFiltered(
      colorFilter: isSelected
          ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
          : const ColorFilter.mode(Colors.grey, BlendMode.saturation),
      child: Image.memory(imageBytes, fit: BoxFit.cover),
    );
  }
}

class _SelectionIndicator extends StatelessWidget {
  const _SelectionIndicator({required this.isSelected});

  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 6,
      right: 6,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? AppColors.primary : Colors.white,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 2,
          ),
        ),
        child: isSelected
            ? const Icon(Icons.check, color: Colors.white, size: 14)
            : null,
      ),
    );
  }
}

class _PreviewButton extends StatelessWidget {
  const _PreviewButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 6,
      left: 6,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(7),
          ),
          child: const Icon(
            Icons.zoom_in_rounded,
            color: Colors.white,
            size: 16,
          ),
        ),
      ),
    );
  }
}

class _ConfidenceBadge extends StatelessWidget {
  const _ConfidenceBadge({required this.confidence});

  final double confidence;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 6,
      left: 6,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          '${(confidence * 100).toStringAsFixed(0)}%',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _ClassificationBadge extends StatelessWidget {
  const _ClassificationBadge({required this.className});

  final String className;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 6,
      right: 6,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          className,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
