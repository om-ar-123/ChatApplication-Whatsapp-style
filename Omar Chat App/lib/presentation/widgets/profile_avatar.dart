import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'media_image.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.name,
    this.imagePath,
    this.radius = 24,
    this.onTap,
  });

  final String name;
  final String? imagePath;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath != null && imagePath!.isNotEmpty;

    Widget avatar = hasImage
        ? ClipOval(
            child: MediaImage(
              path: imagePath!,
              width: radius * 2,
              height: radius * 2,
              fit: BoxFit.cover,
            ),
          )
        : CircleAvatar(
            radius: radius,
            backgroundColor: AppColors.appBar,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(color: Colors.white, fontSize: radius * 0.8),
            ),
          );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: avatar);
    }
    return avatar;
  }
}
