import 'package:flutter/material.dart';
import '../../services/web_blob_store.dart';
import 'platform_file_image.dart' if (dart.library.html) 'platform_file_image_stub.dart';

/// Displays an image from a local path, web blob URL, or in-memory web store.
class MediaImage extends StatelessWidget {
  const MediaImage({
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

  @override
  Widget build(BuildContext context) {
    if (path.startsWith('asset:')) {
      return Image.asset(
        path.substring(6),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, _, _) => _placeholder(),
      );
    }

    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, _, _) => _placeholder(),
      );
    }

    if (path.startsWith('webstore/')) {
      final bytes = WebBlobStore.instance.get(path);
      if (bytes != null) {
        return Image.memory(bytes, width: width, height: height, fit: fit);
      }
      return _placeholder();
    }

    if (path.startsWith('blob:') || path.startsWith('http')) {
      return Image.network(
        path,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, _, _) => _placeholder(),
      );
    }

    return PlatformFileImage(path: path, width: width, height: height, fit: fit);
  }

  Widget _placeholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade300,
      child: const Icon(Icons.broken_image, color: Colors.grey),
    );
  }
}
