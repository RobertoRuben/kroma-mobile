import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:ultralytics_yolo_example/shared/widgets/zoomable_image_mixin.dart';

/// A widget that displays an annotated image with zoom and download capabilities.
///
/// Features:
/// - Pinch to zoom and pan
/// - Double tap to reset zoom
/// - Download button to save image to device
/// - Full screen mode option
class AnnotatedImageViewer extends StatefulWidget {
  const AnnotatedImageViewer({
    super.key,
    required this.imageBytes,
    this.fileName,
    this.showControls = true,
    this.minScale = 0.5,
    this.maxScale = 4.0,
    this.onSaved,
    this.borderRadius = 16.0,
  });

  /// The image data to display
  final Uint8List imageBytes;

  /// Optional file name for saving (without extension)
  final String? fileName;

  /// Whether to show zoom/download controls
  final bool showControls;

  /// Minimum zoom scale
  final double minScale;

  /// Maximum zoom scale
  final double maxScale;

  /// Callback when image is saved successfully
  final VoidCallback? onSaved;

  /// Border radius for the container
  final double borderRadius;

  @override
  State<AnnotatedImageViewer> createState() => _AnnotatedImageViewerState();
}

class _AnnotatedImageViewerState extends State<AnnotatedImageViewer>
    with SingleTickerProviderStateMixin, ZoomableImageMixin {
  @override
  Uint8List get imageBytes => widget.imageBytes;

  @override
  String? get imageSaveFileName => widget.fileName;

  @override
  double get targetZoomScale => 2.0;

  @override
  void initState() {
    super.initState();
    initZoomable();
  }

  @override
  void dispose() {
    disposeZoomable();
    super.dispose();
  }

  void _openFullScreen() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => _FullScreenImageView(
          imageBytes: widget.imageBytes,
          fileName: widget.fileName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          GestureDetector(
            onDoubleTap: onDoubleTap,
            child: InteractiveViewer(
              transformationController: transformationController,
              minScale: widget.minScale,
              maxScale: widget.maxScale,
              child: Image.memory(
                widget.imageBytes,
                fit: BoxFit.contain,
              ),
            ),
          ),
          if (widget.showControls)
            Positioned(
              right: 8,
              bottom: 8,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ControlButton(
                    icon: Icons.refresh_rounded,
                    onTap: resetZoom,
                    tooltip: 'Restablecer zoom',
                  ),
                  const SizedBox(width: 8),
                  _ControlButton(
                    icon: Icons.fullscreen_rounded,
                    onTap: _openFullScreen,
                    tooltip: 'Pantalla completa',
                  ),
                  const SizedBox(width: 8),
                  _ControlButton(
                    icon: isSaving
                        ? Icons.hourglass_empty
                        : Icons.download_rounded,
                    onTap: isSaving
                        ? null
                        : () async {
                            await saveImage();
                            widget.onSaved?.call();
                          },
                    tooltip: 'Descargar imagen',
                    isLoading: isSaving,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.isLoading = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String tooltip;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(8),
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}

class _FullScreenImageView extends StatefulWidget {
  const _FullScreenImageView({
    required this.imageBytes,
    this.fileName,
  });

  final Uint8List imageBytes;
  final String? fileName;

  @override
  State<_FullScreenImageView> createState() => _FullScreenImageViewState();
}

class _FullScreenImageViewState extends State<_FullScreenImageView>
    with SingleTickerProviderStateMixin, ZoomableImageMixin {
  @override
  Uint8List get imageBytes => widget.imageBytes;

  @override
  String? get imageSaveFileName => widget.fileName;

  @override
  double get targetZoomScale => 2.5;

  @override
  void initState() {
    super.initState();
    initZoomable();
  }

  @override
  void dispose() {
    disposeZoomable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Vista de imagen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: resetZoom,
            tooltip: 'Restablecer zoom',
          ),
          IconButton(
            icon: isSaving
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.download_rounded),
            onPressed: isSaving ? null : saveImage,
            tooltip: 'Descargar imagen',
          ),
        ],
      ),
      body: GestureDetector(
        onDoubleTap: onDoubleTap,
        child: InteractiveViewer(
          transformationController: transformationController,
          minScale: 0.5,
          maxScale: 5.0,
          child: Center(
            child: Image.memory(
              widget.imageBytes,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
