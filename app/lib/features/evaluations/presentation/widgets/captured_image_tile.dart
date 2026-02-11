import 'package:flutter/material.dart';
import 'package:ultralytics_yolo_example/features/evaluations/domain/models/captured_image.dart';

/// Tile widget for displaying a captured image in the shot gallery grid.
/// Shows the photo number, GPS coordinates if available, and a delete button.
class CapturedImageTile extends StatelessWidget {
  const CapturedImageTile({
    super.key,
    required this.item,
    required this.index,
    required this.onRemove,
  });

  final CapturedImage item;
  final int index;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(
              image: item.imageProvider,
              fit: BoxFit.cover,
            ),
          ),
        ),
        // Index + GPS badge
        Positioned(
          bottom: 6,
          left: 6,
          right: 6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Foto #$index',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (item.latitude != null && item.longitude != null)
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 9, color: Colors.white70),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          '${item.latitude!.toStringAsFixed(4)}, ${item.longitude!.toStringAsFixed(4)}',
                          style: const TextStyle(color: Colors.white70, fontSize: 8),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        // Delete Button
        Positioned(
          top: 4,
          right: 4,
          child: IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close_rounded),
            style: IconButton.styleFrom(
              backgroundColor: Colors.black54,
              foregroundColor: Colors.white,
              padding: EdgeInsets.zero,
              minimumSize: const Size(24, 24),
            ),
          ),
        ),
      ],
    );
  }
}
