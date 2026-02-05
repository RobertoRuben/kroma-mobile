// Ultralytics 🚀 AGPL-3.0 License - https://ultralytics.com/license

import 'package:flutter/material.dart';
import 'package:ultralytics_yolo_example/shared/models/models.dart';
import 'package:ultralytics_yolo_example/shared/widgets/control_button.dart';

/// A widget containing camera control buttons
class CameraControls extends StatelessWidget {
  const CameraControls({
    super.key,
    required this.currentZoomLevel,
    required this.activeSlider,
    required this.onZoomChanged,
    required this.onSliderToggled,
    required this.isLandscape,
  });

  final double currentZoomLevel;
  final SliderType activeSlider;
  final ValueChanged<double> onZoomChanged;
  final ValueChanged<SliderType> onSliderToggled;
  final bool isLandscape;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          bottom: isLandscape ? 16 : 32,
          right: isLandscape ? 8 : 16,
          child: Column(
            children: [
              ControlButton.text(
                text: '${currentZoomLevel.toStringAsFixed(1)}x',
                onPressed: () => onZoomChanged(
                  currentZoomLevel < 0.75
                      ? 1.0
                      : currentZoomLevel < 2.0
                      ? 3.0
                      : 0.5,
                ),
              ),
              SizedBox(height: isLandscape ? 8 : 12),
              ControlButton.icon(
                icon: Icons.layers,
                onPressed: () => onSliderToggled(SliderType.numItems),
              ),
              SizedBox(height: isLandscape ? 8 : 12),
              ControlButton.icon(
                icon: Icons.adjust,
                onPressed: () => onSliderToggled(SliderType.confidence),
              ),
              SizedBox(height: isLandscape ? 8 : 12),
              ControlButton.image(
                assetPath: 'assets/iou.png',
                onPressed: () => onSliderToggled(SliderType.iou),
              ),
              SizedBox(height: isLandscape ? 16 : 40),
            ],
          ),
        ),
        // Flip camera button removed - only back camera is used for counting
      ],
    );
  }
}
