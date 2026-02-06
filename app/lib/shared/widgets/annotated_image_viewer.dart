import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ultralytics_yolo_example/core/theme/app_colors.dart';

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
    with SingleTickerProviderStateMixin {
  final TransformationController _transformationController =
      TransformationController();
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _resetZoom() {
    _animation = Matrix4Tween(
      begin: _transformationController.value,
      end: Matrix4.identity(),
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animation!.addListener(() {
      _transformationController.value = _animation!.value;
    });

    _animationController.forward(from: 0);
  }

  void _onDoubleTap() {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    if (currentScale > 1.0) {
      _resetZoom();
    } else {
      final zoomMatrix = Matrix4.diagonal3Values(2.0, 2.0, 1.0);
      _animation = Matrix4Tween(
        begin: _transformationController.value,
        end: zoomMatrix,
      ).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
      );

      _animation!.addListener(() {
        _transformationController.value = _animation!.value;
      });

      _animationController.forward(from: 0);
    }
  }

  Future<void> _saveImage() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      // Save to temp file first, then to gallery
      final tempDir = await getTemporaryDirectory();
      final fileName = widget.fileName ?? 'kroma_${DateTime.now().millisecondsSinceEpoch}';
      final filePath = '${tempDir.path}/$fileName.png';

      final file = File(filePath);
      await file.writeAsBytes(widget.imageBytes);

      // Save to gallery
      await Gal.putImage(filePath, album: 'Kroma');

      // Clean up temp file
      if (await file.exists()) {
        await file.delete();
      }

      if (mounted) {
        _showSnackBar('Imagen guardada en galería', isError: false);
        widget.onSaved?.call();
      }
    } on GalException catch (e) {
      if (mounted) {
        _showSnackBar('Error al guardar: ${e.type.message}', isError: true);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error al guardar: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.destructive : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
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
            onDoubleTap: _onDoubleTap,
            child: InteractiveViewer(
              transformationController: _transformationController,
              minScale: widget.minScale,
              maxScale: widget.maxScale,
              child: Image.memory(
                widget.imageBytes,
                fit: BoxFit.contain,
              ),
            ),
          ),
          if (widget.showControls) _buildControls(),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Positioned(
      right: 8,
      bottom: 8,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ControlButton(
            icon: Icons.refresh_rounded,
            onTap: _resetZoom,
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
            icon: _isSaving ? Icons.hourglass_empty : Icons.download_rounded,
            onTap: _isSaving ? null : _saveImage,
            tooltip: 'Descargar imagen',
            isLoading: _isSaving,
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
    with SingleTickerProviderStateMixin {
  final TransformationController _transformationController =
      TransformationController();
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _resetZoom() {
    _animation = Matrix4Tween(
      begin: _transformationController.value,
      end: Matrix4.identity(),
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animation!.addListener(() {
      _transformationController.value = _animation!.value;
    });

    _animationController.forward(from: 0);
  }

  void _onDoubleTap() {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    if (currentScale > 1.0) {
      _resetZoom();
    } else {
      final zoomMatrix = Matrix4.diagonal3Values(2.5, 2.5, 1.0);
      _animation = Matrix4Tween(
        begin: _transformationController.value,
        end: zoomMatrix,
      ).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
      );

      _animation!.addListener(() {
        _transformationController.value = _animation!.value;
      });

      _animationController.forward(from: 0);
    }
  }

  Future<void> _saveImage() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      // Save to temp file first, then to gallery
      final tempDir = await getTemporaryDirectory();
      final fileName = widget.fileName ?? 'kroma_${DateTime.now().millisecondsSinceEpoch}';
      final filePath = '${tempDir.path}/$fileName.png';

      final file = File(filePath);
      await file.writeAsBytes(widget.imageBytes);

      // Save to gallery
      await Gal.putImage(filePath, album: 'Kroma');

      // Clean up temp file
      if (await file.exists()) {
        await file.delete();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Imagen guardada en galería'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on GalException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: ${e.type.message}'),
            backgroundColor: AppColors.destructive,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: AppColors.destructive,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
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
            onPressed: _resetZoom,
            tooltip: 'Restablecer zoom',
          ),
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.download_rounded),
            onPressed: _isSaving ? null : _saveImage,
            tooltip: 'Descargar imagen',
          ),
        ],
      ),
      body: GestureDetector(
        onDoubleTap: _onDoubleTap,
        child: InteractiveViewer(
          transformationController: _transformationController,
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
