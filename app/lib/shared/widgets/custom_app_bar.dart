import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ultralytics_yolo_example/core/theme/app_colors.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions,
    this.centerTitle = true,
    this.elevation = 0,
    this.backgroundColor,
    this.foregroundColor,
    this.showBackButton = true,
    this.onBackPressed,
  });

  final String title;

  final String? subtitle;

  final Widget? leading;

  final List<Widget>? actions;

  final bool centerTitle;

  final double elevation;

  final Color? backgroundColor;

  final Color? foregroundColor;

  final bool showBackButton;

  final VoidCallback? onBackPressed;

  @override
  Size get preferredSize =>
      Size.fromHeight(subtitle != null ? kToolbarHeight + 16 : kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? AppColors.primary;
    final fgColor = foregroundColor ?? AppColors.textOnPrimary;

    return AppBar(
      backgroundColor: bgColor,
      foregroundColor: fgColor,
      elevation: elevation,
      centerTitle: centerTitle,
      leading: _buildLeading(context, fgColor),
      title: _buildTitle(fgColor),
      actions: actions,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: elevation == 0 ? AppColors.primaryGradient : null,
        ),
      ),
    );
  }

  Widget? _buildLeading(BuildContext context, Color fgColor) {
    if (leading != null) return leading;

    if (showBackButton && Navigator.canPop(context)) {
      return IconButton(
        icon: Icon(Icons.arrow_back_ios_new, color: fgColor),
        onPressed: onBackPressed ?? () => Navigator.pop(context),
      );
    }

    return null;
  }

  Widget _buildTitle(Color fgColor) {
    if (subtitle == null) {
      return Text(
        title,
        style: TextStyle(
          color: fgColor,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: centerTitle
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: fgColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle!,
          style: TextStyle(
            color: fgColor.withValues(alpha: 0.8),
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class TransparentAppBar extends CustomAppBar {
  const TransparentAppBar({
    super.key,
    required super.title,
    super.subtitle,
    super.leading,
    super.actions,
    super.centerTitle = true,
    super.showBackButton = true,
    super.onBackPressed,
  }) : super(backgroundColor: Colors.transparent, elevation: 0);
}
