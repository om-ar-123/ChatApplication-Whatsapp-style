import 'dart:io';
import 'package:flutter/material.dart';

class PlatformFileImage extends StatelessWidget {
  const PlatformFileImage({
    super.key,
    required this.path,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  final String path;
  final double? width;
  final double? height;
  final BoxFit fit;

  static bool exists(String path) => File(path).existsSync();

  @override
  Widget build(BuildContext context) {
    if (!File(path).existsSync()) {
      return Container(
        width: width,
        height: height,
        color: Colors.grey.shade300,
        child: const Icon(Icons.broken_image),
      );
    }
    return Image.file(File(path), width: width, height: height, fit: fit);
  }
}
