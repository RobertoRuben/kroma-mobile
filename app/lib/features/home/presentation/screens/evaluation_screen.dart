import 'package:flutter/material.dart';
import 'package:ultralytics_yolo_example/core/core.dart';
import 'package:ultralytics_yolo_example/features/inference/presentation/screens/camera_inference_screen.dart';
import 'package:ultralytics_yolo_example/shared/models/models.dart';

class EvaluationScreen extends StatelessWidget {
  const EvaluationScreen({
    super.key,
    required this.selectedModel,
    required this.confidenceThreshold,
  });

  final ModelType selectedModel;
  final double confidenceThreshold;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Evaluación', showBackButton: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _EvaluationCard(
              title: 'Conteo por surcos',
              description:
                  'Realiza el conteo automático de plantines por surco en tiempo real.',
              icon: Icons.forest_rounded,
              color: AppColors.primary,
              onTap: () {
                // Navigate to existing camera inference screen
                // Defaulting to int8 and 0.5 confidence as per previous Home defaults
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CameraInferenceScreen(
                      initialModel: selectedModel,
                      initialConfidence: confidenceThreshold,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _EvaluationCard(
              title: 'Evaluación de densidad',
              description:
                  'Evalúa la densidad de siembra y distribución de plantas.',
              icon: Icons.grid_on_rounded, // or another appropriate icon
              color:
                  AppColors.secondary, // Using secondary color for distinction
              onTap: () {
                // Placeholder for now
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Módulo de Evaluación de densidad próximamente',
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _EvaluationCard extends StatelessWidget {
  const _EvaluationCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: color, width: 6)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
