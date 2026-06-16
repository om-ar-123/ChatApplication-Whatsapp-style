import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class DrawingBoardWidget extends StatefulWidget {
  const DrawingBoardWidget({super.key, required this.onSave, required this.onClose});

  final ValueChanged<List<int>> onSave;
  final VoidCallback onClose;

  @override
  State<DrawingBoardWidget> createState() => _DrawingBoardWidgetState();
}

class _DrawingBoardWidgetState extends State<DrawingBoardWidget> {
  final GlobalKey _repaintKey = GlobalKey();
  final List<Offset?> _points = [];

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      child: SafeArea(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: widget.onClose),
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.white),
                  onPressed: _saveDrawing,
                ),
              ],
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                color: Colors.white,
                child: GestureDetector(
                  onPanUpdate: (d) => setState(() => _points.add(d.localPosition)),
                  onPanEnd: (_) => _points.add(null),
                  child: RepaintBoundary(
                    key: _repaintKey,
                    child: CustomPaint(
                      painter: _DrawingPainter(_points),
                      size: Size.infinite,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveDrawing() async {
    final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;
    final image = await boundary.toImage(pixelRatio: 2);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData != null) {
      widget.onSave(byteData.buffer.asUint8List());
    }
    widget.onClose();
  }
}

class _DrawingPainter extends CustomPainter {
  _DrawingPainter(this.points);
  final List<Offset?> points;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
