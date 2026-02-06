// Ultralytics 🚀 AGPL-3.0 License - https://ultralytics.com/license

import 'package:flutter/material.dart';
import 'package:ultralytics_yolo/yolo_streaming_config.dart';
import 'package:ultralytics_yolo/yolo_view.dart';
import '../controllers/camera_inference_controller.dart';
import 'model_loading_overlay.dart';

/// Main content widget that handles the camera view and loading states
class CameraInferenceContent extends StatefulWidget {
  const CameraInferenceContent({
    super.key,
    required this.controller,
    this.rebuildKey = 0,
  });

  final CameraInferenceController controller;
  final int rebuildKey;

  @override
  State<CameraInferenceContent> createState() => _CameraInferenceContentState();
}

class _CameraInferenceContentState extends State<CameraInferenceContent> {
  // Store initial model path to avoid recreating YOLOView on model switch
  String? _initialModelPath;
  int _initialRebuildKey = 0;

  @override
  void initState() {
    super.initState();
    _initialModelPath = widget.controller.modelPath;
    _initialRebuildKey = widget.rebuildKey;
  }

  @override
  void didUpdateWidget(CameraInferenceContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only update initial values if rebuildKey changed (navigation)
    // or if we're loading for the first time
    if (widget.rebuildKey != oldWidget.rebuildKey) {
      _initialRebuildKey = widget.rebuildKey;
      _initialModelPath = widget.controller.modelPath;
    } else if (_initialModelPath == null && widget.controller.modelPath != null) {
      _initialModelPath = widget.controller.modelPath;
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    
    // Show loading overlay while switching models (but keep camera running underneath)
    if (controller.isModelLoading && _initialModelPath == null) {
      // Only show full loading overlay for first model load
      return ModelLoadingOverlay(
        loadingMessage: controller.loadingMessage,
        downloadProgress: controller.downloadProgress,
      );
    }
    
    if (controller.modelPath != null || _initialModelPath != null) {
      final modelPath = _initialModelPath ?? controller.modelPath!;
      return Stack(
        children: [
          YOLOView(
            // Use stable key based on initial model and rebuildKey only
            key: ValueKey('yolo_view_stable_$_initialRebuildKey'),
            controller: controller.yoloController,
            modelPath: modelPath,
            task: controller.selectedModel.task,
            streamingConfig: YOLOStreamingConfig.highPerformance(),
            onResult: controller.onDetectionResults,
            onPerformanceMetrics: (metrics) =>
                controller.onPerformanceMetrics(metrics.fps),
            onZoomChanged: controller.onZoomChanged,
            lensFacing: controller.lensFacing,
          ),
          // Show subtle loading indicator during hot-swap
          if (controller.isModelLoading)
            Positioned(
              top: 80,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        controller.loadingMessage,
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
    } else {
      return const Center(
        child: Text('No model loaded', style: TextStyle(color: Colors.white)),
      );
    }
  }
}
