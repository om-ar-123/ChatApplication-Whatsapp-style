import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// WhatsApp-style subtle doodle wallpaper overlay.
class ChatWallpaper extends StatelessWidget {
  const ChatWallpaper({super.key, required this.child, this.backgroundColor});

  final Widget child;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor ?? AppColors.chatBackground,
      child: CustomPaint(
        painter: _WallpaperPainter(),
        child: child,
      ),
    );
  }
}

class _WallpaperPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFCCD0C8).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    const step = 48.0;
    for (var x = 0.0; x < size.width + step; x += step) {
      for (var y = 0.0; y < size.height + step; y += step) {
        final cx = x + step / 2;
        final cy = y + step / 2;
        canvas.drawCircle(Offset(cx, cy), 3, paint);
        canvas.drawLine(Offset(cx - 6, cy), Offset(cx + 6, cy), paint);
        canvas.drawLine(Offset(cx, cy - 6), Offset(cx, cy + 6), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
