import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ultralytics_yolo_example/core/theme/app_colors.dart';

/// Mixin that provides zoom, double-tap and save-to-gallery logic
/// for any [State] that uses [SingleTickerProviderStateMixin].
///
/// Consumers must override [imageBytes], [fileName] and [targetZoomScale].
mixin ZoomableImageMixin<T extends StatefulWidget>
    on State<T>, SingleTickerProviderStateMixin<T> {
  final TransformationController transformationController =
      TransformationController();
  late final AnimationController zoomAnimationController;
  Animation<Matrix4>? _zoomAnimation;
  bool isSaving = false;

  /// Raw bytes of the image to display / save.
  Uint8List get imageBytes;

  /// Optional file name (without extension) used when saving.
  String? get imageSaveFileName;

  /// Scale applied on double-tap zoom-in (e.g. 2.0, 2.5).
  double get targetZoomScale;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  void initZoomable() {
    zoomAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  void disposeZoomable() {
    transformationController.dispose();
    zoomAnimationController.dispose();
  }

  // ---------------------------------------------------------------------------
  // Zoom helpers
  // ---------------------------------------------------------------------------

  void resetZoom() {
    _animateTo(Matrix4.identity());
  }

  void onDoubleTap() {
    final currentScale = transformationController.value.getMaxScaleOnAxis();
    if (currentScale > 1.0) {
      resetZoom();
    } else {
      _animateTo(
        Matrix4.diagonal3Values(targetZoomScale, targetZoomScale, 1.0),
      );
    }
  }

  void _animateTo(Matrix4 target) {
    _zoomAnimation = Matrix4Tween(
      begin: transformationController.value,
      end: target,
    ).animate(
      CurvedAnimation(
        parent: zoomAnimationController,
        curve: Curves.easeOut,
      ),
    );

    _zoomAnimation!.addListener(() {
      transformationController.value = _zoomAnimation!.value;
    });

    zoomAnimationController.forward(from: 0);
  }

  // ---------------------------------------------------------------------------
  // Save to gallery
  // ---------------------------------------------------------------------------

  Future<void> saveImage() async {
    if (isSaving) return;

    setState(() => isSaving = true);

    try {
      final tempDir = await getTemporaryDirectory();
      final name =
          imageSaveFileName ?? 'kroma_${DateTime.now().millisecondsSinceEpoch}';
      final filePath = '${tempDir.path}/$name.png';

      final file = File(filePath);
      await file.writeAsBytes(imageBytes);

      await Gal.putImage(filePath, album: 'Kroma');

      if (await file.exists()) {
        await file.delete();
      }

      if (mounted) {
        showImageSnackBar('Imagen guardada en galería', isError: false);
      }
    } on GalException catch (e) {
      if (mounted) {
        showImageSnackBar('Error al guardar: ${e.type.message}', isError: true);
      }
    } catch (e) {
      if (mounted) {
        showImageSnackBar('Error al guardar: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  void showImageSnackBar(String message, {required bool isError}) {
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
}
