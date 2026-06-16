import 'package:flutter/material.dart';
import '../../data/models/message_model.dart';
import 'media_image.dart';

class AttachmentPreview extends StatelessWidget {
  const AttachmentPreview({
    super.key,
    this.path,
    this.name,
    required this.type,
  });

  final String? path;
  final String? name;
  final String type;

  @override
  Widget build(BuildContext context) {
    if (path != null &&
        path!.isNotEmpty &&
        (type == MessageModel.typeImage || type == MessageModel.typeDrawing)) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: MediaImage(path: path!, height: 150, width: 200, fit: BoxFit.cover),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(_iconForType(type)),
        const SizedBox(width: 8),
        Flexible(
          child: Text(name ?? 'Attachment', overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case MessageModel.typeFile:
        return Icons.attach_file;
      case MessageModel.typeImage:
      case MessageModel.typeDrawing:
        return Icons.image;
      default:
        return Icons.file_present;
    }
  }
}
