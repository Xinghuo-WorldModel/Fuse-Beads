import 'package:flutter/material.dart';
import '../models/bead_color.dart';
import '../services/pixel_converter.dart';

class BeadGridPainter extends CustomPainter {
  final ConvertResult result;
  final bool showCodes;
  final double cellSize;
  final int revision;

  BeadGridPainter({
    required this.result,
    this.showCodes = false,
    this.cellSize = 20,
    this.revision = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final gridPaint = Paint()
      ..color = Colors.black26
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    for (int y = 0; y < result.height; y++) {
      for (int x = 0; x < result.width; x++) {
        final cell = result.grid[y][x];
        final rect = Rect.fromLTWH(
          x * cellSize,
          y * cellSize,
          cellSize,
          cellSize,
        );

        // Fill cell with bead color
        paint.color = cell.beadColor.color;
        canvas.drawRect(rect, paint);

        // Draw grid line
        canvas.drawRect(rect, gridPaint);

        // Draw color code if zoomed in enough
        if (showCodes && cellSize >= 16) {
          _drawCode(canvas, rect, cell.beadColor);
        }
      }
    }
  }

  void _drawCode(Canvas canvas, Rect rect, BeadColor bead) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: bead.code,
        style: TextStyle(
          fontSize: cellSize * 0.3,
          color: _contrastColor(bead.color),
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.layout(maxWidth: rect.width);
    textPainter.paint(
      canvas,
      Offset(
        rect.left + (rect.width - textPainter.width) / 2,
        rect.top + (rect.height - textPainter.height) / 2,
      ),
    );
  }

  Color _contrastColor(Color color) {
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }

  @override
  bool shouldRepaint(covariant BeadGridPainter oldDelegate) {
    return oldDelegate.result != result ||
        oldDelegate.showCodes != showCodes ||
        oldDelegate.cellSize != cellSize ||
        oldDelegate.revision != revision;
  }
}
