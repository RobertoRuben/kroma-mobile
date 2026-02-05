import 'package:flutter/material.dart';
import 'package:ultralytics_yolo_example/core/theme/app_colors.dart';

class AppContent extends StatelessWidget {
  const AppContent({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
    this.scrollable = true,
    this.safeArea = true,
  });

  /// The content to display
  final Widget child;

  /// Custom padding (defaults to horizontal 16)
  final EdgeInsetsGeometry? padding;

  /// Background color
  final Color? backgroundColor;

  /// Whether the content should be scrollable
  final bool scrollable;

  /// Whether to wrap in SafeArea
  final bool safeArea;

  @override
  Widget build(BuildContext context) {
    Widget content = Padding(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
      child: child,
    );

    if (scrollable) {
      content = SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: content,
      );
    }

    if (safeArea) {
      content = SafeArea(top: false, child: content);
    }

    return Container(
      color: backgroundColor ?? AppColors.background,
      child: content,
    );
  }
}

/// A card wrapper with consistent styling
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.elevation = 0,
    this.borderRadius = 12,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final double elevation;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(vertical: 8),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        elevation: elevation,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Container(
            padding: padding ?? const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
