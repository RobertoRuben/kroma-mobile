import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ultralytics_yolo_example/core/core.dart';
import 'package:ultralytics_yolo_example/features/evaluations/domain/models/captured_image.dart';
import 'package:ultralytics_yolo_example/features/evaluations/presentation/screens/evaluation_result_screen.dart';
import 'package:ultralytics_yolo_example/features/evaluations/presentation/widgets/captured_image_tile.dart';

/// Screen for capturing multiple photos with GPS tags before evaluation
class ShotGalleryScreen extends StatefulWidget {
  const ShotGalleryScreen({super.key});

  @override
  State<ShotGalleryScreen> createState() => _ShotGalleryScreenState();
}

class _ShotGalleryScreenState extends State<ShotGalleryScreen> {
  final List<CapturedImage> _capturedImages = [];
  final ImagePicker _picker = ImagePicker();

  // Cached permission status — checked once on init
  bool _cameraGranted = false;
  bool _locationGranted = false;
  bool _permissionsChecked = false;
  bool _isTakingPhoto = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPermissionsAndTakeFirstPhoto();
    });
  }

  /// Check permissions once, then take the first photo
  Future<void> _checkPermissionsAndTakeFirstPhoto() async {
    await _checkPermissions();
    if (!mounted) return;
    if (_cameraGranted) {
      await _takePhoto();
    }
  }

  /// Check and request permissions once, cache the results
  Future<void> _checkPermissions() async {
    if (_permissionsChecked) return;

    final statuses = await [
      Permission.camera,
      Permission.location,
    ].request();

    _cameraGranted = statuses[Permission.camera]?.isGranted ?? false;
    _locationGranted = statuses[Permission.location]?.isGranted ?? false;
    _permissionsChecked = true;

    if (!_cameraGranted && mounted) {
      _showPermissionDeniedDialog();
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permisos requeridos'),
        content: const Text(
          'Esta función requiere acceso a la cámara. La ubicación es opcional pero recomendada.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Go back from gallery too
            },
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Abrir Configuración'),
          ),
        ],
      ),
    );
  }

  Future<void> _takePhoto() async {
    if (!_cameraGranted || _isTakingPhoto) return;
    _isTakingPhoto = true;

    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
      );

      if (photo == null) {
        // User cancelled camera
        if (_capturedImages.isEmpty && mounted) {
          Navigator.pop(context);
        }
        return;
      }

      final int photoIndex = _capturedImages.length;

      if (mounted) {
        setState(() {
          _capturedImages.add(
            CapturedImage(
              file: photo,
              latitude: null,
              longitude: null,
            ),
          );
        });
      }

      // Get GPS in background (non-blocking)
      if (_locationGranted) {
        _updatePhotoWithGPS(photoIndex);
      }
    } catch (e) {
      debugPrint('Error in takePhoto: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      _isTakingPhoto = false;
    }
  }

  /// Updates photo at [index] with GPS coordinates asynchronously
  Future<void> _updatePhotoWithGPS(int index) async {
    Position? position;

    try {
      // Try last known position first (instant, works offline)
      position = await Geolocator.getLastKnownPosition();

      // If no cached position, try current with short timeout
      position ??= await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      debugPrint('GPS error (non-blocking): $e');
    }

    if (position != null && mounted && index < _capturedImages.length) {
      setState(() {
        final oldItem = _capturedImages[index];
        _capturedImages[index] = CapturedImage(
          file: oldItem.file,
          latitude: position!.latitude,
          longitude: position.longitude,
        );
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _capturedImages.removeAt(index);
    });
  }

  void _finish() {
    if (_capturedImages.isEmpty) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => EvaluationResultScreen(
          imageFiles: _capturedImages.map((c) => c.file).toList(),
          capturedImages: _capturedImages,
          sourceIsCamera: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: CustomAppBar(
        title: 'Captura',
        subtitle: '${_capturedImages.length} fotos tomadas',
        showBackButton: true,
      ),
      body: Column(
        children: [
          // Gallery Grid
          Expanded(
            child: _capturedImages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt_outlined,
                          size: 64,
                          color: context.textSecondaryColor.withValues(
                            alpha: 0.3,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Toma tu primera foto',
                          style: TextStyle(
                            color: context.textSecondaryColor,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 0.75,
                        ),
                    itemCount: _capturedImages.length,
                    itemBuilder: (context, index) {
                      final item = _capturedImages[index];
                      return RepaintBoundary(
                        key: ValueKey(item.file.path),
                        child: CapturedImageTile(
                          item: item,
                          index: index + 1,
                          onRemove: () => _removeImage(index),
                        ),
                      );
                    },
                  ),
          ),
          // Bottom Bar
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: context.cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _takePhoto,
                    icon: const Icon(Icons.add_a_photo_rounded),
                    label: const Text('Agregar Foto'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppColors.primary),
                      foregroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _capturedImages.isNotEmpty ? _finish : null,
                    icon: const Icon(Icons.check_rounded),
                    label: Text('Procesar (${_capturedImages.length})'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
