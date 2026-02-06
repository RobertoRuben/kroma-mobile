import 'package:flutter/material.dart';
import 'package:ultralytics_yolo_example/core/core.dart';
import 'package:ultralytics_yolo_example/shared/models/models.dart';

/// A bottom sheet for configuring inference settings.
///
/// Provides controls for:
/// - Detector model selection
/// - Classifier model selection
/// - Confidence threshold adjustment (applies to detector only)
class SettingsBottomSheet extends StatefulWidget {
  const SettingsBottomSheet({
    super.key,
    required this.controller,
  });

  final SettingsController controller;

  /// Shows the settings bottom sheet.
  static Future<void> show(BuildContext context, SettingsController controller) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SettingsBottomSheet(controller: controller),
    );
  }

  @override
  State<SettingsBottomSheet> createState() => _SettingsBottomSheetState();
}

class _SettingsBottomSheetState extends State<SettingsBottomSheet> {
  late ModelType _selectedDetector;
  late ModelType _selectedClassifier;
  late double _confidenceThreshold;

  @override
  void initState() {
    super.initState();
    _selectedDetector = widget.controller.selectedDetector;
    _selectedClassifier = widget.controller.selectedClassifier;
    _confidenceThreshold = widget.controller.confidenceThreshold;
  }

  bool _isLoading = false;
  String _loadingMessage = '';

  Future<void> _applyChanges() async {
    if (_isLoading) return;

    final preloader = ModelPreloader.instance;
    final needsDetectorReload = _selectedDetector != preloader.currentDetectorType;
    final needsClassifierReload = _selectedClassifier != preloader.currentClassifierType;
    final thresholdChanged =
        (widget.controller.confidenceThreshold - _confidenceThreshold).abs() > 0.01;

    // Update settings controller immediately
    widget.controller.setDetector(_selectedDetector);
    widget.controller.setClassifier(_selectedClassifier);
    widget.controller.setConfidenceThreshold(_confidenceThreshold);

    // If models need reloading, stay open and show spinner
    if (needsDetectorReload || needsClassifierReload) {
      setState(() {
        _isLoading = true;
        _loadingMessage = needsDetectorReload && needsClassifierReload
            ? 'Cargando detector y clasificador...'
            : needsDetectorReload
                ? 'Cargando detector ${_selectedDetector.displayName}...'
                : 'Cargando clasificador ${_selectedClassifier.displayName}...';
      });

      try {
        if (needsDetectorReload) {
          setState(() => _loadingMessage = 'Cargando detector ${_selectedDetector.displayName}...');
          final ok = await preloader.loadDetector(_selectedDetector);
          if (!ok) throw Exception('Error cargando detector');
        }
        if (needsClassifierReload) {
          setState(() => _loadingMessage = 'Cargando clasificador ${_selectedClassifier.displayName}...');
          final ok = await preloader.loadClassifier(_selectedClassifier);
          if (!ok) throw Exception('Error cargando clasificador');
        }

        if (mounted) {
          Navigator.pop(context);
          _showToast(context, 'Modelos cargados correctamente', isSuccess: true);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          _showToast(context, 'Error al cargar modelo: $e', isSuccess: false);
        }
      }
    } else {
      // Only threshold changed (or nothing changed) — close immediately
      if (mounted) {
        Navigator.pop(context);
        if (thresholdChanged) {
          _showToast(
            context,
            'Umbral actualizado a ${(_confidenceThreshold * 100).toInt()}%',
            isSuccess: true,
          );
        }
      }
    }
  }

  void _showToast(BuildContext context, String message, {required bool isSuccess}) {
    // Use rootNavigator context to ensure the SnackBar shows after bottom sheet closes
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle_rounded : Icons.error_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: isSuccess ? AppColors.success : AppColors.destructive,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.borderDark : AppColors.secondary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            _buildHeader(isDark),
            Divider(height: 1, color: isDark ? AppColors.dividerDark : AppColors.divider),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Modelo Detector', isDark),
                    const SizedBox(height: 12),
                    _buildDetectorSelector(isDark),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Modelo Clasificador', isDark),
                    const SizedBox(height: 12),
                    _buildClassifierSelector(isDark),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Umbral de Confianza (Detector)', isDark),
                    const SizedBox(height: 12),
                    _buildConfidenceSlider(isDark),
                    const SizedBox(height: 32),
                    _buildApplyButton(isDark),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 16, 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.tune_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Configuración',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Ajusta los parámetros de inferencia',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.cardDark
                  : AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              onPressed: _isLoading ? null : () => Navigator.pop(context),
              icon: const Icon(Icons.close_rounded, size: 20),
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildDetectorSelector(bool isDark) {
    return _ModelSelector<ModelType>(
      options: SettingsController.detectorModels,
      selectedValue: _selectedDetector,
      onChanged: _isLoading ? null : (value) => setState(() => _selectedDetector = value),
      labelBuilder: (model) => model.displayName,
      descriptionBuilder: _getDetectorDescription,
      isDark: isDark,
    );
  }

  Widget _buildClassifierSelector(bool isDark) {
    return _ModelSelector<ModelType>(
      options: SettingsController.classifierModels,
      selectedValue: _selectedClassifier,
      onChanged: _isLoading ? null : (value) => setState(() => _selectedClassifier = value),
      labelBuilder: (model) => model.displayName,
      descriptionBuilder: _getClassifierDescription,
      isDark: isDark,
    );
  }

  String _getDetectorDescription(ModelType model) {
    switch (model) {
      case ModelType.detectorInt8:
        return 'Rápido, menor precisión';
      case ModelType.detectorFloat16:
        return 'Equilibrado';
      case ModelType.detectorFloat32:
        return 'Mayor precisión, más lento';
      default:
        return '';
    }
  }

  String _getClassifierDescription(ModelType model) {
    switch (model) {
      case ModelType.maturityFloat16:
        return 'Equilibrado';
      case ModelType.maturityFloat32:
        return 'Mayor precisión';
      default:
        return '';
    }
  }

  Widget _buildConfidenceSlider(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Confianza mínima',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${(_confidenceThreshold * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.primary.withValues(alpha: 0.2),
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withValues(alpha: 0.1),
              trackHeight: 4,
              disabledActiveTrackColor: AppColors.primary.withValues(alpha: 0.5),
              disabledInactiveTrackColor: AppColors.primary.withValues(alpha: 0.1),
              disabledThumbColor: AppColors.primary.withValues(alpha: 0.5),
            ),
            child: Slider(
              value: _confidenceThreshold,
              min: 0.1,
              max: 0.95,
              divisions: 17,
              onChanged: _isLoading ? null : (value) => setState(() => _confidenceThreshold = value),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '10%',
                style: TextStyle(fontSize: 11, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
              ),
              Text(
                '95%',
                style: TextStyle(fontSize: 11, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildApplyButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _applyChanges,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? AppColors.primaryHover : AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: (isDark ? AppColors.primaryHover : AppColors.primary).withValues(alpha: 0.5),
          disabledForegroundColor: Colors.white70,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      _loadingMessage,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              )
            : const Text(
                'Guardar y Aplicar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}

class _ModelSelector<T> extends StatelessWidget {
  const _ModelSelector({
    required this.options,
    required this.selectedValue,
    required this.onChanged,
    required this.labelBuilder,
    required this.descriptionBuilder,
    required this.isDark,
  });

  final List<T> options;
  final T selectedValue;
  final ValueChanged<T>? onChanged;
  final String Function(T) labelBuilder;
  final String Function(T) descriptionBuilder;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onChanged != null;

    return Column(
      children: options.map((option) {
        final isSelected = option == selectedValue;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: isEnabled ? () => onChanged!(option) : null,
            borderRadius: BorderRadius.circular(12),
            child: Opacity(
              opacity: isEnabled ? 1.0 : 0.6,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : (isDark ? AppColors.backgroundDark : AppColors.background),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : (isDark ? AppColors.borderDark : AppColors.border),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : (isDark ? AppColors.borderDark : AppColors.border),
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? Center(
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primary,
                                ),
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            labelBuilder(option),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  isSelected ? FontWeight.w600 : FontWeight.normal,
                              color: isSelected
                                  ? AppColors.primary
                                  : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
                            ),
                          ),
                          Text(
                            descriptionBuilder(option),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
