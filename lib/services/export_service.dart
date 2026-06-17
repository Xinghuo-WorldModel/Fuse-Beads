import 'dart:typed_data';
import 'package:image/image.dart' as img;
import '../models/bead_color.dart';
import '../models/project_config.dart';
import 'pixel_converter.dart';

class ExportService {
  static const int _cellSize = 40;
  static const int _headerHeight = 60;
  static const int _legendRowHeight = 30;
  static const int _padding = 20;

  /// Generate export image as PNG bytes
  Future<Uint8List> exportToBytes(ConvertResult result, ProjectConfig config) async {
    final gridWidth = result.width * _cellSize;
    final gridHeight = result.height * _cellSize;

    final sortedUsage = result.colorUsage.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final legendHeight = sortedUsage.length * _legendRowHeight + _padding * 2;

    final totalWidth = gridWidth + _padding * 2;
    final totalHeight = _headerHeight + gridHeight + legendHeight + _padding * 3;

    final image = img.Image(width: totalWidth, height: totalHeight);
    img.fill(image, color: img.ColorRgba8(255, 255, 255, 255));

    _drawHeader(image, config, result);
    _drawGrid(image, result);
    _drawLegend(image, result, config, gridHeight);

    return Uint8List.fromList(img.encodePng(image));
  }

  void _drawHeader(img.Image image, ProjectConfig config, ConvertResult result) {
    final modeName = config.mode == ConvertMode.pixel ? 'Pixel' : 'Realistic';
    final totalBeads = result.colorUsage.values.fold(0, (sum, v) => sum + v);

    img.fillRect(
      image,
      x1: 0,
      y1: 0,
      x2: image.width,
      y2: _headerHeight,
      color: img.ColorRgba8(103, 80, 164, 255),
    );

    img.drawString(
      image,
      'PinDou - $modeName | ${config.brand.name} | '
      '${result.width}x${result.height} | $totalBeads beads | ${result.colorUsage.length} colors',
      font: img.arial14,
      x: _padding,
      y: 20,
      color: img.ColorRgba8(255, 255, 255, 255),
    );
  }

  void _drawGrid(img.Image image, ConvertResult result) {
    const offsetY = _headerHeight + _padding;

    for (int y = 0; y < result.height; y++) {
      for (int x = 0; x < result.width; x++) {
        final cell = result.grid[y][x];
        final bead = cell.beadColor;

        final px = _padding + x * _cellSize;
        final py = offsetY + y * _cellSize;

        img.fillRect(
          image,
          x1: px,
          y1: py,
          x2: px + _cellSize,
          y2: py + _cellSize,
          color: img.ColorRgba8(bead.r, bead.g, bead.b, 255),
        );

        img.drawRect(
          image,
          x1: px,
          y1: py,
          x2: px + _cellSize - 1,
          y2: py + _cellSize - 1,
          color: img.ColorRgba8(0, 0, 0, 60),
        );

        final textColor = _getContrastColor(bead.r, bead.g, bead.b);
        img.drawString(
          image,
          bead.code,
          font: img.arial14,
          x: px + 4,
          y: py + (_cellSize - 14) ~/ 2,
          color: textColor,
        );
      }
    }
  }

  void _drawLegend(
    img.Image image,
    ConvertResult result,
    ProjectConfig config,
    int gridHeight,
  ) {
    final offsetY = _headerHeight + _padding + gridHeight + _padding;
    final sortedUsage = result.colorUsage.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final totalBeads = result.colorUsage.values.fold(0, (sum, v) => sum + v);

    img.drawString(
      image,
      'Color | Code | Name | Count | Percent',
      font: img.arial14,
      x: _padding,
      y: offsetY,
      color: img.ColorRgba8(0, 0, 0, 255),
    );

    for (int i = 0; i < sortedUsage.length; i++) {
      final entry = sortedUsage[i];
      final bead = config.brand.colors.firstWhere(
        (c) => c.code == entry.key,
        orElse: () => BeadColor(code: entry.key, name: '未知', hex: '#CCCCCC'),
      );
      final percent = totalBeads == 0
          ? '0.0'
          : (entry.value / totalBeads * 100).toStringAsFixed(1);
      final rowY = offsetY + (i + 1) * _legendRowHeight;

      img.fillRect(
        image,
        x1: _padding,
        y1: rowY + 2,
        x2: _padding + 20,
        y2: rowY + 22,
        color: img.ColorRgba8(bead.r, bead.g, bead.b, 255),
      );
      img.drawRect(
        image,
        x1: _padding,
        y1: rowY + 2,
        x2: _padding + 20,
        y2: rowY + 22,
        color: img.ColorRgba8(0, 0, 0, 100),
      );

      img.drawString(
        image,
        '${bead.code}  ${bead.name}  x${entry.value}  ($percent%)',
        font: img.arial14,
        x: _padding + 28,
        y: rowY + 5,
        color: img.ColorRgba8(0, 0, 0, 255),
      );
    }
  }

  img.Color _getContrastColor(int r, int g, int b) {
    final luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255;
    return luminance > 0.5
        ? img.ColorRgba8(0, 0, 0, 200)
        : img.ColorRgba8(255, 255, 255, 230);
  }
}
