import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Represents a photo captured by the camera with optional GPS data
class CapturedImage {
  CapturedImage({required this.file, this.latitude, this.longitude});

  final XFile file;
  final double? latitude;
  final double? longitude;

  /// Cached FileImage to avoid recreation on every build
  FileImage? _cachedImage;
  FileImage get imageProvider => _cachedImage ??= FileImage(File(file.path));
}
