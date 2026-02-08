import 'package:flutter/material.dart';
import 'package:ultralytics_yolo_example/core/core.dart';

/// Action bar at the bottom with Add Photo + Finalize buttons
class CropActionBar extends StatelessWidget {
  const CropActionBar({
    super.key,
    required this.onClassify,
    required this.totalSelected,
    required this.imageCount,
    this.onAddFromCamera,
    this.onAddFromGallery,
  });

  final VoidCallback? onClassify;
  final int totalSelected;
  final int imageCount;
  final VoidCallback? onAddFromCamera;
  final VoidCallback? onAddFromGallery;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onAddFromCamera,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.4),
                      ),
                    ),
                    icon: const Icon(Icons.camera_alt_rounded, size: 18),
                    label: const Text(
                      'Tomar otra foto',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onAddFromGallery,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(
                        color: AppColors.accent.withValues(alpha: 0.4),
                      ),
                    ),
                    icon: const Icon(Icons.photo_library_rounded, size: 18),
                    label: const Text(
                      'Agregar galería',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onClassify,
                style: ElevatedButton.styleFrom(
                  backgroundColor: onClassify != null
                      ? AppColors.primary
                      : AppColors.disabled,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.auto_awesome),
                label: Text(
                  totalSelected > 0
                      ? 'Finalizar y Clasificar ($totalSelected recortes · $imageCount fotos)'
                      : 'Selecciona recortes para clasificar',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
