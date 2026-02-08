import 'package:flutter/material.dart';
import 'package:ultralytics_yolo_example/core/core.dart';

/// Reusable content section header with a colored accent bar and title text.
///
/// Different from [SectionHeader] in app_header.dart which uses uppercase
/// and primary-colored text. This variant uses normal case and larger text,
/// suited for detail/content screens.
class ContentSectionHeader extends StatelessWidget {
  const ContentSectionHeader({
    super.key,
    required this.title,
    this.color = AppColors.primary,
    this.trailing,
  });

  final String title;
  final Color color;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: context.textPrimaryColor,
            letterSpacing: -0.3,
          ),
        ),
        if (trailing != null) ...[
          const Spacer(),
          trailing!,
        ],
      ],
    );
  }
}
