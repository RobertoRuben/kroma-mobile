// Ultralytics 🚀 AGPL-3.0 License - https://ultralytics.com/license

import 'package:flutter/material.dart';

/// A circular control button that can display an icon, image, or text
/// A circular control button that can display an icon, image, or text
class ControlButton extends StatelessWidget {
  const ControlButton._({
    super.key,
    required this.child,
    required this.onPressed,
  });

  /// Create a button with an Icon
  factory ControlButton.icon({
    Key? key,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return ControlButton._(
      key: key,
      onPressed: onPressed,
      child: Icon(icon, color: Colors.white, size: 24),
    );
  }

  /// Create a button with an Asset Image
  factory ControlButton.image({
    Key? key,
    required String assetPath,
    required VoidCallback onPressed,
  }) {
    return ControlButton._(
      key: key,
      onPressed: onPressed,
      child: Image.asset(assetPath, width: 24, height: 24, color: Colors.white),
    );
  }

  /// Create a button with Text
  factory ControlButton.text({
    Key? key,
    required String text,
    required VoidCallback onPressed,
  }) {
    return ControlButton._(
      key: key,
      onPressed: onPressed,
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }

  final Widget child;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 24,
      backgroundColor: Colors.black.withValues(alpha: 0.2),
      child: IconButton(icon: child, onPressed: onPressed),
    );
  }
}
