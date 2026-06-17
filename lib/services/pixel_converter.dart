import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import '../models/bead_color.dart';
import '../models/project_config.dart';
import 'color_matcher.dart';

class BeadGridCell {
  final int x;
  final int y;
  BeadColor beadColor;

  BeadGridCell({required this.x, required this.y, required this.beadColor});
}

class ConvertResult {
  final List<List<BeadGridCell>> grid;
  final int width;
  final int height;
  final Map<String, int> colorUsage;

  ConvertResult({
    required this.grid,
    required this.width,
    required this.height,
    required this.colorUsage,
  });

  /// Recompute color usage statistics from the current grid
  void recomputeUsage() {
    colorUsage.clear();
    for (final row in grid) {
      for (final cell in row) {
        final code = cell.beadColor.code;
        colorUsage[code] = (colorUsage[code] ?? 0) + 1;
      }
    }
  }

  /// Change the color of a single cell and update statistics
  void setCellColor(int x, int y, BeadColor newColor) {
    if (y < 0 || y >= height || x < 0 || x >= width) return;
    grid[y][x].beadColor = newColor;
    recomputeUsage();
  }
}

class PixelConverter {
  final ColorMatcher _colorMatcher = ColorMatcher();

  /// Pixel art style: downscale + edge enhance + dithering
  ConvertResult convertPixelStyle(
    img.Image source,
    List<BeadColor> palette,
    GridSize gridSize, {
    int maxColors = 30,
  }) {
    var processed = _autoWhiteBalance(source);
    processed = _adaptiveContrast(processed);

    processed = img.copyResize(
      processed,
      width: gridSize.width,
      height: gridSize.height,
      interpolation: img.Interpolation.average,
    );

    processed = _sharpen(processed, strength: 0.5);

    final limitedPalette = _selectOptimalPaletteKMeans(
      processed, palette, maxColors,
    );
    return _mapWithSerpentineDithering(
      processed, limitedPalette, gridSize,
      ditherStrength: 0.85,
    );
  }

  /// Realistic style: high quality downscale + dithering
  ConvertResult convertRealisticStyle(
    img.Image source,
    List<BeadColor> palette,
    GridSize gridSize, {
    int maxColors = 30,
  }) {
    var processed = _autoWhiteBalance(source);
    processed = _adaptiveContrast(processed, strength: 0.8);

    processed = img.copyResize(
      processed,
      width: gridSize.width,
      height: gridSize.height,
      interpolation: img.Interpolation.cubic,
    );

    final limitedPalette = _selectOptimalPaletteKMeans(
      processed, palette, maxColors,
    );
    final skinPalette = ColorMatcher.extractSkinColors(limitedPalette);
    return _mapWithSerpentineDithering(
      processed, limitedPalette, gridSize,
      skinPalette: skinPalette,
      ditherStrength: 0.7,
    );
  }

  /// Serpentine Floyd-Steinberg dithering (alternating scan direction)
  ConvertResult _mapWithSerpentineDithering(
    img.Image image,
    List<BeadColor> palette,
    GridSize gridSize, {
    List<BeadColor>? skinPalette,
    double ditherStrength = 0.85,
  }) {
    _colorMatcher.clearCache();
    final Map<String, int> colorUsage = {};
    final List<List<BeadGridCell>> grid = [];

    final w = image.width;
    final h = image.height;

    // Error buffer in floating point RGB
    final errors = List.generate(
      h, (_) => List.generate(w, (_) => [0.0, 0.0, 0.0]),
    );

    for (int y = 0; y < h; y++) {
      final List<BeadGridCell> row = List.filled(
        w, BeadGridCell(x: 0, y: 0, beadColor: palette.first),
      );
      final bool leftToRight = (y % 2 == 0);
      final int startX = leftToRight ? 0 : w - 1;
      final int endX = leftToRight ? w : -1;
      final int step = leftToRight ? 1 : -1;

      for (int x = startX; x != endX; x += step) {
        final pixel = image.getPixel(x, y);

        int r = (pixel.r.toInt() + errors[y][x][0]).round().clamp(0, 255);
        int g = (pixel.g.toInt() + errors[y][x][1]).round().clamp(0, 255);
        int b = (pixel.b.toInt() + errors[y][x][2]).round().clamp(0, 255);

        final color = Color.fromARGB(255, r, g, b);

        // Reduce dither strength for skin tones
        double localStrength = ditherStrength;
        if (ColorMatcher.isSkinTone(r, g, b)) {
          localStrength *= 0.5;
        }

        BeadColor bead;
        if (skinPalette != null && skinPalette.isNotEmpty) {
          bead = _colorMatcher.findClosestWithSkinPriority(
            color, palette, skinPalette,
          );
        } else {
          bead = _colorMatcher.findClosest(color, palette);
        }

        final errR = (r - bead.r) * localStrength;
        final errG = (g - bead.g) * localStrength;
        final errB = (b - bead.b) * localStrength;

        _distributeSerpentine(
          errors, x, y, w, h, errR, errG, errB, leftToRight,
        );

        colorUsage[bead.code] = (colorUsage[bead.code] ?? 0) + 1;
        row[x] = BeadGridCell(x: x, y: y, beadColor: bead);
      }
      grid.add(row);
    }

    return ConvertResult(
      grid: grid,
      width: gridSize.width,
      height: gridSize.height,
      colorUsage: colorUsage,
    );
  }

  void _distributeSerpentine(
    List<List<List<double>>> errors,
    int x, int y, int w, int h,
    double errR, double errG, double errB,
    bool leftToRight,
  ) {
    final dir = leftToRight ? 1 : -1;
    const coefficients = [7.0 / 16, 3.0 / 16, 5.0 / 16, 1.0 / 16];

    // Right (or left if reversed)
    final nx1 = x + dir;
    if (nx1 >= 0 && nx1 < w) {
      errors[y][nx1][0] += errR * coefficients[0];
      errors[y][nx1][1] += errG * coefficients[0];
      errors[y][nx1][2] += errB * coefficients[0];
    }
    // Below-left (or below-right if reversed)
    if (y + 1 < h) {
      final nx2 = x - dir;
      if (nx2 >= 0 && nx2 < w) {
        errors[y + 1][nx2][0] += errR * coefficients[1];
        errors[y + 1][nx2][1] += errG * coefficients[1];
        errors[y + 1][nx2][2] += errB * coefficients[1];
      }
      // Below
      errors[y + 1][x][0] += errR * coefficients[2];
      errors[y + 1][x][1] += errG * coefficients[2];
      errors[y + 1][x][2] += errB * coefficients[2];
      // Below-right (or below-left if reversed)
      final nx3 = x + dir;
      if (nx3 >= 0 && nx3 < w) {
        errors[y + 1][nx3][0] += errR * coefficients[3];
        errors[y + 1][nx3][1] += errG * coefficients[3];
        errors[y + 1][nx3][2] += errB * coefficients[3];
      }
    }
  }

  /// K-Means based optimal palette selection
  List<BeadColor> _selectOptimalPaletteKMeans(
    img.Image image,
    List<BeadColor> fullPalette,
    int maxColors,
  ) {
    if (fullPalette.length <= maxColors) return fullPalette;

    _colorMatcher.clearCache();

    // Sample pixels from image (max 2000 for performance)
    final pixels = <List<int>>[];
    final sampleStep = max(1, (image.width * image.height) ~/ 2000);
    int idx = 0;
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        if (idx % sampleStep == 0) {
          final p = image.getPixel(x, y);
          pixels.add([p.r.toInt(), p.g.toInt(), p.b.toInt()]);
        }
        idx++;
      }
    }

    // Run K-Means in Lab space to find cluster centers
    final labPixels = pixels
        .map((p) => ColorMatcher.rgbToLab(p[0], p[1], p[2]))
        .toList();

    final centers = _kMeansLab(labPixels, maxColors, iterations: 8);

    // For each cluster center, find the closest bead color
    final selected = <BeadColor>{};
    final paletteLabs = fullPalette
        .map((b) => ColorMatcher.rgbToLab(b.r, b.g, b.b))
        .toList();

    for (final center in centers) {
      double minDist = double.infinity;
      int bestIdx = 0;
      for (int i = 0; i < fullPalette.length; i++) {
        final dist = ColorMatcher.deltaE2000(center, paletteLabs[i]);
        if (dist < minDist) {
          minDist = dist;
          bestIdx = i;
        }
      }
      selected.add(fullPalette[bestIdx]);
    }

    // If duplicates reduced count, fill with frequency-based picks
    if (selected.length < maxColors) {
      final freq = <String, int>{};
      for (int y = 0; y < image.height; y++) {
        for (int x = 0; x < image.width; x++) {
          final p = image.getPixel(x, y);
          final c = Color.fromARGB(255, p.r.toInt(), p.g.toInt(), p.b.toInt());
          final bead = _colorMatcher.findClosest(c, fullPalette);
          freq[bead.code] = (freq[bead.code] ?? 0) + 1;
        }
      }
      final sorted = freq.keys.toList()
        ..sort((a, b) => freq[b]!.compareTo(freq[a]!));
      for (final code in sorted) {
        if (selected.length >= maxColors) break;
        final bead = fullPalette.firstWhere((c) => c.code == code);
        selected.add(bead);
      }
    }

    _colorMatcher.clearCache();
    return selected.toList();
  }

  /// Simple K-Means clustering in Lab color space
  List<LabColor> _kMeansLab(
    List<LabColor> points, int k, {int iterations = 8}
  ) {
    if (points.isEmpty) return [];
    final rng = Random(42);
    k = min(k, points.length);

    // Initialize centers using K-Means++ strategy
    final centers = <LabColor>[points[rng.nextInt(points.length)]];
    while (centers.length < k) {
      final dists = points.map((p) {
        double minD = double.infinity;
        for (final c in centers) {
          final d = _labDistSq(p, c);
          if (d < minD) minD = d;
        }
        return minD;
      }).toList();

      final totalDist = dists.reduce((a, b) => a + b);
      if (totalDist == 0) break;
      double target = rng.nextDouble() * totalDist;
      for (int i = 0; i < points.length; i++) {
        target -= dists[i];
        if (target <= 0) {
          centers.add(points[i]);
          break;
        }
      }
    }

    // Iterate
    var assignments = List.filled(points.length, 0);
    for (int iter = 0; iter < iterations; iter++) {
      // Assign points to nearest center
      for (int i = 0; i < points.length; i++) {
        double minD = double.infinity;
        int best = 0;
        for (int c = 0; c < centers.length; c++) {
          final d = _labDistSq(points[i], centers[c]);
          if (d < minD) { minD = d; best = c; }
        }
        assignments[i] = best;
      }

      // Update centers
      for (int c = 0; c < centers.length; c++) {
        double sumL = 0, sumA = 0, sumB = 0;
        int count = 0;
        for (int i = 0; i < points.length; i++) {
          if (assignments[i] == c) {
            sumL += points[i].l;
            sumA += points[i].a;
            sumB += points[i].b;
            count++;
          }
        }
        if (count > 0) {
          centers[c] = LabColor(sumL / count, sumA / count, sumB / count);
        }
      }
    }

    return centers;
  }

  double _labDistSq(LabColor a, LabColor b) {
    final dl = a.l - b.l;
    final da = a.a - b.a;
    final db = a.b - b.b;
    return dl * dl + da * da + db * db;
  }

  /// Auto white balance using gray world assumption
  img.Image _autoWhiteBalance(img.Image source) {
    final result = img.Image.from(source);
    double sumR = 0, sumG = 0, sumB = 0;
    final total = source.width * source.height;

    for (int y = 0; y < source.height; y++) {
      for (int x = 0; x < source.width; x++) {
        final p = source.getPixel(x, y);
        sumR += p.r.toInt();
        sumG += p.g.toInt();
        sumB += p.b.toInt();
      }
    }

    final avgR = sumR / total;
    final avgG = sumG / total;
    final avgB = sumB / total;
    final avgGray = (avgR + avgG + avgB) / 3.0;

    // Only correct if imbalance is significant
    if ((avgR - avgGray).abs() < 5 &&
        (avgG - avgGray).abs() < 5 &&
        (avgB - avgGray).abs() < 5) {
      return source;
    }

    final scaleR = avgGray / (avgR == 0 ? 1 : avgR);
    final scaleG = avgGray / (avgG == 0 ? 1 : avgG);
    final scaleB = avgGray / (avgB == 0 ? 1 : avgB);

    for (int y = 0; y < result.height; y++) {
      for (int x = 0; x < result.width; x++) {
        final p = result.getPixel(x, y);
        final r = (p.r.toInt() * scaleR).round().clamp(0, 255);
        final g = (p.g.toInt() * scaleG).round().clamp(0, 255);
        final b = (p.b.toInt() * scaleB).round().clamp(0, 255);
        result.setPixelRgba(x, y, r, g, b, 255);
      }
    }
    return result;
  }

  /// Adaptive contrast enhancement (simplified CLAHE)
  img.Image _adaptiveContrast(img.Image source, {double strength = 1.0}) {
    final result = img.Image.from(source);
    final w = source.width;
    final h = source.height;

    // Compute luminance histogram
    final hist = List.filled(256, 0);
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final p = source.getPixel(x, y);
        final lum = (0.299 * p.r.toInt() +
                     0.587 * p.g.toInt() +
                     0.114 * p.b.toInt()).round().clamp(0, 255);
        hist[lum]++;
      }
    }

    // Clip histogram (limit contrast amplification)
    final total = w * h;
    final clipLimit = (total / 256 * 2.5).round();
    int excess = 0;
    for (int i = 0; i < 256; i++) {
      if (hist[i] > clipLimit) {
        excess += hist[i] - clipLimit;
        hist[i] = clipLimit;
      }
    }
    final redistrib = excess ~/ 256;
    for (int i = 0; i < 256; i++) {
      hist[i] += redistrib;
    }

    // Build CDF lookup table
    final cdf = List.filled(256, 0);
    cdf[0] = hist[0];
    for (int i = 1; i < 256; i++) {
      cdf[i] = cdf[i - 1] + hist[i];
    }
    final cdfMin = cdf.firstWhere((v) => v > 0, orElse: () => 0);
    final lut = List.filled(256, 0);
    final denom = total - cdfMin;
    for (int i = 0; i < 256; i++) {
      lut[i] = denom > 0
          ? ((cdf[i] - cdfMin) * 255 / denom).round().clamp(0, 255)
          : i;
    }

    // Apply with blending based on strength
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final p = source.getPixel(x, y);
        final r = p.r.toInt();
        final g = p.g.toInt();
        final b = p.b.toInt();
        final lum = (0.299 * r + 0.587 * g + 0.114 * b).round().clamp(0, 255);
        final newLum = lut[lum];
        final ratio = lum > 0 ? newLum / lum : 1.0;

        final nr = (r * (1 - strength) + r * ratio * strength)
            .round().clamp(0, 255);
        final ng = (g * (1 - strength) + g * ratio * strength)
            .round().clamp(0, 255);
        final nb = (b * (1 - strength) + b * ratio * strength)
            .round().clamp(0, 255);
        result.setPixelRgba(x, y, nr, ng, nb, 255);
      }
    }
    return result;
  }

  /// Sharpening with configurable strength
  img.Image _sharpen(img.Image source, {double strength = 0.5}) {
    final result = img.Image.from(source);
    for (int y = 1; y < source.height - 1; y++) {
      for (int x = 1; x < source.width - 1; x++) {
        final center = source.getPixel(x, y);
        final top = source.getPixel(x, y - 1);
        final bottom = source.getPixel(x, y + 1);
        final left = source.getPixel(x - 1, y);
        final right = source.getPixel(x + 1, y);

        final r = (center.r.toInt() * 5 - top.r.toInt() - bottom.r.toInt() - left.r.toInt() - right.r.toInt()).clamp(0, 255);
        final g = (center.g.toInt() * 5 - top.g.toInt() - bottom.g.toInt() - left.g.toInt() - right.g.toInt()).clamp(0, 255);
        final b = (center.b.toInt() * 5 - top.b.toInt() - bottom.b.toInt() - left.b.toInt() - right.b.toInt()).clamp(0, 255);

        final fr = (r * strength + center.r.toInt() * (1 - strength)).round().clamp(0, 255);
        final fg = (g * strength + center.g.toInt() * (1 - strength)).round().clamp(0, 255);
        final fb = (b * strength + center.b.toInt() * (1 - strength)).round().clamp(0, 255);

        result.setPixelRgba(x, y, fr, fg, fb, 255);
      }
    }
    return result;
  }
}
