import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ultralytics_yolo_example/core/core.dart';
import 'package:ultralytics_yolo_example/features/evaluations/presentation/screens/evaluation_result_screen.dart';

class EvaluationOptionsScreen extends StatelessWidget {
  const EvaluationOptionsScreen({super.key});

  /// Pick a single image from camera and navigate
  Future<void> _pickFromCamera(BuildContext context) async {
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(source: ImageSource.camera);

      if (file != null && context.mounted) {
        _navigateToEvaluation(
          context,
          imageFiles: [file],
          sourceIsCamera: true,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al capturar imagen: $e')),
        );
      }
    }
  }

  /// Pick multiple images from gallery and navigate
  Future<void> _pickFromGallery(BuildContext context) async {
    try {
      final picker = ImagePicker();
      final List<XFile> files = await picker.pickMultiImage();

      if (files.isNotEmpty && context.mounted) {
        _navigateToEvaluation(
          context,
          imageFiles: files,
          sourceIsCamera: false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar imágenes: $e')),
        );
      }
    }
  }

  void _navigateToEvaluation(
    BuildContext context, {
    required List<XFile> imageFiles,
    required bool sourceIsCamera,
  }) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            EvaluationResultScreen(
          imageFiles: imageFiles,
          sourceIsCamera: sourceIsCamera,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const curve = Curves.easeOutCubic;
          final curvedAnimation =
              CurvedAnimation(parent: animation, curve: curve);
          return FadeTransition(
            opacity: curvedAnimation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.05, 0),
                end: Offset.zero,
              ).animate(curvedAnimation),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 250),
        reverseTransitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: const CustomAppBar(
        title: 'Evaluaciones',
        subtitle: 'Análisis de imágenes',
        showBackButton: false,
      ),
      body: _EvaluationBody(
        onPickFromCamera: _pickFromCamera,
        onPickFromGallery: _pickFromGallery,
      ),
    );
  }
}

/// Body widget separated for better performance
class _EvaluationBody extends StatelessWidget {
  const _EvaluationBody({
    required this.onPickFromCamera,
    required this.onPickFromGallery,
  });

  final Future<void> Function(BuildContext) onPickFromCamera;
  final Future<void> Function(BuildContext) onPickFromGallery;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Illustration / header area
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: isDark ? null : AppColors.primaryGradient,
              color: isDark ? AppColors.primaryDark.withValues(alpha: 0.3) : null,
              borderRadius: BorderRadius.circular(24),
              border: isDark ? Border.all(color: AppColors.borderDark) : null,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.science_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Análisis Inteligente',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Detecta y clasifica con IA avanzada',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Source selection label
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Seleccionar fuente',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimaryColor,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _OptionCard(
            title: 'Nueva Evaluación',
            subtitle: 'Tomar foto con la cámara',
            icon: Icons.camera_alt_rounded,
            color: AppColors.primary,
            onTap: () => onPickFromCamera(context),
          ),
          const SizedBox(height: 14),
          _OptionCard(
            title: 'Desde Galería',
            subtitle: 'Seleccionar múltiples fotos',
            icon: Icons.photo_library_rounded,
            color: AppColors.accent,
            onTap: () => onPickFromGallery(context),
          ),
          const Spacer(),
          // Tip area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.info.withValues(alpha: 0.08)
                  : AppColors.infoLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.info.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.lightbulb_outline_rounded,
                  color: AppColors.info,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Consejo: Usa buena iluminación para mejores resultados',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.info : AppColors.info,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Reusable option card widget
class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Material(
      color: context.cardColor,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        splashColor: color.withValues(alpha: 0.08),
        highlightColor: color.withValues(alpha: 0.04),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? context.borderColor : color.withValues(alpha: 0.15),
              width: 1,
            ),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: color.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: isDark ? 0.15 : 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: context.textPrimaryColor,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: context.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: isDark ? 0.12 : 0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: color,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
