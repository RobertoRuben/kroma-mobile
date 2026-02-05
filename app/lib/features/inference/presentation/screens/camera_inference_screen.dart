import 'package:flutter/material.dart';

import 'package:ultralytics_yolo_example/shared/models/models.dart';
import '../controllers/camera_inference_controller.dart';
import '../widgets/camera_inference_content.dart';
import '../widgets/detection_stats_overlay.dart';
import '../widgets/model_loading_overlay.dart';

/// A screen that demonstrates real-time YOLO object detection using the device camera.
///
/// This screen provides:
/// - Live camera feed with YOLO object detection
/// - Counting line for seedling counting
/// - Stats display (count, detections, FPS)
/// - Simple controls (reset, stop)
/// - ROI zone counting for objects crossing the counting line
class CameraInferenceScreen extends StatefulWidget {
  const CameraInferenceScreen({
    super.key,
    this.initialModel,
    this.initialConfidence,
  });

  /// Initial model type to use
  final ModelType? initialModel;

  /// Initial confidence threshold
  final double? initialConfidence;

  @override
  State<CameraInferenceScreen> createState() => _CameraInferenceScreenState();
}

class _CameraInferenceScreenState extends State<CameraInferenceScreen> {
  late final CameraInferenceController _controller;
  int _rebuildKey = 0;

  @override
  void initState() {
    super.initState();
    _controller = CameraInferenceController(
      initialModel: widget.initialModel,
      initialConfidence: widget.initialConfidence,
    );
    _controller.initialize().catchError((error) {
      if (mounted) {
        _showError('Model Loading Error', error.toString());
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check if route is current (we've navigated back to this screen)
    final route = ModalRoute.of(context);
    if (route?.isCurrent == true) {
      // Force rebuild when navigating back to ensure camera restarts
      // The rebuild will create a new YOLOView which will automatically start the camera
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _rebuildKey++;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleStop() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera feed - Static relative to high-frequency stats
          CameraInferenceContent(
            key: ValueKey('camera_content_$_rebuildKey'),
            controller: _controller,
            rebuildKey: _rebuildKey,
          ),

          // Detection Stats - Dynamic, rebuilds on controller changes
          ListenableBuilder(
            listenable: _controller,
            builder: (context, child) {
              if (_controller.isModelLoading) return const SizedBox.shrink();

              return Positioned(
                bottom: 24,
                left: 16,
                right: 16,
                child: DetectionStatsOverlay(
                  detectionCount: _controller.detectionCount,
                  fps: _controller.currentFps,
                  selectedModel: _controller.selectedModel,
                  onStop: _handleStop,
                ),
              );
            },
          ),

          // Loading Overlay - Topmost layer
          ListenableBuilder(
            listenable: _controller,
            builder: (context, child) {
              if (!_controller.isModelLoading) return const SizedBox.shrink();

              return ModelLoadingOverlay(
                loadingMessage: _controller.loadingMessage,
                downloadProgress: _controller.downloadProgress,
              );
            },
          ),
        ],
      ),
    );
  }

  void _showError(String title, String message) => showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
