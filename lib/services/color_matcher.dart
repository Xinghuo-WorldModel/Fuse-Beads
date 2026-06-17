import 'dart:math';
import 'package:flutter/material.dart';
import '../models/bead_color.dart';

class LabColor {
  final double l;
  final double a;
  final double b;

  const LabColor(this.l, this.a, this.b);
}

class ColorMatcher {
  final Map<int, BeadColor> _cache = {};
  final Map<int, LabColor> _labCache = {};

  /// RGB -> XYZ (D65 illuminant)
  static List<double> rgbToXyz(int r, int g, int b) {
    double rr = r / 255.0;
    double gg = g / 255.0;
    double bb = b / 255.0;

    rr = rr > 0.04045 ? pow((rr + 0.055) / 1.055, 2.4).toDouble() : rr / 12.92;
    gg = gg > 0.04045 ? pow((gg + 0.055) / 1.055, 2.4).toDouble() : gg / 12.92;
    bb = bb > 0.04045 ? pow((bb + 0.055) / 1.055, 2.4).toDouble() : bb / 12.92;

    rr *= 100;
    gg *= 100;
    bb *= 100;

    final x = rr * 0.4124564 + gg * 0.3575761 + bb * 0.1804375;
    final y = rr * 0.2126729 + gg * 0.7151522 + bb * 0.0721750;
    final z = rr * 0.0193339 + gg * 0.1191920 + bb * 0.9503041;

    return [x, y, z];
  }

  /// XYZ -> CIE Lab
  static LabColor xyzToLab(double x, double y, double z) {
    const refX = 95.047;
    const refY = 100.000;
    const refZ = 108.883;

    double xx = x / refX;
    double yy = y / refY;
    double zz = z / refZ;

    xx = xx > 0.008856 ? pow(xx, 1.0 / 3.0).toDouble() : (7.787 * xx) + (16.0 / 116.0);
    yy = yy > 0.008856 ? pow(yy, 1.0 / 3.0).toDouble() : (7.787 * yy) + (16.0 / 116.0);
    zz = zz > 0.008856 ? pow(zz, 1.0 / 3.0).toDouble() : (7.787 * zz) + (16.0 / 116.0);

    final l = (116.0 * yy) - 16.0;
    final a = 500.0 * (xx - yy);
    final b = 200.0 * (yy - zz);

    return LabColor(l, a, b);
  }

  /// RGB -> CIE Lab with caching
  LabColor rgbToLabCached(int r, int g, int b) {
    final key = (r << 16) | (g << 8) | b;
    if (_labCache.containsKey(key)) return _labCache[key]!;
    final xyz = rgbToXyz(r, g, b);
    final lab = xyzToLab(xyz[0], xyz[1], xyz[2]);
    _labCache[key] = lab;
    return lab;
  }

  static LabColor rgbToLab(int r, int g, int b) {
    final xyz = rgbToXyz(r, g, b);
    return xyzToLab(xyz[0], xyz[1], xyz[2]);
  }

  /// CIEDE2000 - perceptually accurate color difference
  static double deltaE2000(LabColor lab1, LabColor lab2) {
    final l1 = lab1.l, a1 = lab1.a, b1 = lab1.b;
    final l2 = lab2.l, a2 = lab2.a, b2 = lab2.b;

    final lBarPrime = (l1 + l2) / 2.0;
    final c1 = sqrt(a1 * a1 + b1 * b1);
    final c2 = sqrt(a2 * a2 + b2 * b2);
    final cBar = (c1 + c2) / 2.0;

    final cBar7 = pow(cBar, 7).toDouble();
    final g = 0.5 * (1 - sqrt(cBar7 / (cBar7 + pow(25, 7))));

    final a1Prime = a1 * (1 + g);
    final a2Prime = a2 * (1 + g);

    final c1Prime = sqrt(a1Prime * a1Prime + b1 * b1);
    final c2Prime = sqrt(a2Prime * a2Prime + b2 * b2);
    final cBarPrime = (c1Prime + c2Prime) / 2.0;

    double h1Prime = atan2(b1, a1Prime) * 180 / pi;
    if (h1Prime < 0) h1Prime += 360;
    double h2Prime = atan2(b2, a2Prime) * 180 / pi;
    if (h2Prime < 0) h2Prime += 360;

    double hBarPrime;
    if ((h1Prime - h2Prime).abs() > 180) {
      hBarPrime = (h1Prime + h2Prime + 360) / 2.0;
    } else {
      hBarPrime = (h1Prime + h2Prime) / 2.0;
    }

    final t = 1 -
        0.17 * cos((hBarPrime - 30) * pi / 180) +
        0.24 * cos((2 * hBarPrime) * pi / 180) +
        0.32 * cos((3 * hBarPrime + 6) * pi / 180) -
        0.20 * cos((4 * hBarPrime - 63) * pi / 180);

    double dhPrime;
    if ((h2Prime - h1Prime).abs() <= 180) {
      dhPrime = h2Prime - h1Prime;
    } else if (h2Prime - h1Prime > 180) {
      dhPrime = h2Prime - h1Prime - 360;
    } else {
      dhPrime = h2Prime - h1Prime + 360;
    }

    final dlPrime = l2 - l1;
    final dcPrime = c2Prime - c1Prime;
    final dHPrime = 2 * sqrt(c1Prime * c2Prime) * sin(dhPrime * pi / 360);

    final sl = 1 + (0.015 * pow(lBarPrime - 50, 2)) / sqrt(20 + pow(lBarPrime - 50, 2));
    final sc = 1 + 0.045 * cBarPrime;
    final sh = 1 + 0.015 * cBarPrime * t;

    final cBarPrime7 = pow(cBarPrime, 7).toDouble();
    final rt = -2 *
        sqrt(cBarPrime7 / (cBarPrime7 + pow(25, 7))) *
        sin(60 * exp(-pow((hBarPrime - 275) / 25, 2)) * pi / 180);

    final result = sqrt(
      pow(dlPrime / sl, 2) +
          pow(dcPrime / sc, 2) +
          pow(dHPrime / sh, 2) +
          rt * (dcPrime / sc) * (dHPrime / sh),
    );

    return result;
  }

  /// Find the closest bead color using CIEDE2000
  BeadColor findClosest(Color pixel, List<BeadColor> palette) {
    final key = pixel.value;
    if (_cache.containsKey(key)) return _cache[key]!;

    final pixelLab = rgbToLabCached(pixel.red, pixel.green, pixel.blue);
    double minDist = double.infinity;
    BeadColor closest = palette.first;

    for (final bead in palette) {
      final beadLab = rgbToLabCached(bead.r, bead.g, bead.b);
      final dist = deltaE2000(pixelLab, beadLab);
      if (dist < minDist) {
        minDist = dist;
        closest = bead;
      }
    }

    _cache[key] = closest;
    return closest;
  }

  /// Check if a color is in skin tone range (expanded detection)
  static bool isSkinTone(int r, int g, int b) {
    // Multi-rule skin detection for diverse skin tones
    // Rule 1: RGB ratio based
    if (r > 50 && g > 30 && b > 15 &&
        r > g && r > b &&
        (r - g).abs() > 10 &&
        r - b > 15) {
      final maxC = max(r, max(g, b));
      final minC = min(r, min(g, b));
      if (maxC > 0) {
        final saturation = (maxC - minC) / maxC;
        if (saturation > 0.05 && saturation < 0.75) return true;
      }
    }

    // Rule 2: YCbCr based (covers more skin tones)
    final y = 0.299 * r + 0.587 * g + 0.114 * b;
    final cb = -0.169 * r - 0.331 * g + 0.500 * b + 128;
    final cr = 0.500 * r - 0.419 * g - 0.081 * b + 128;

    if (y > 40 && cb > 77 && cb < 127 && cr > 133 && cr < 173) {
      return true;
    }

    return false;
  }

  /// Find closest with skin tone priority
  BeadColor findClosestWithSkinPriority(
    Color pixel,
    List<BeadColor> palette,
    List<BeadColor> skinPalette,
  ) {
    if (isSkinTone(pixel.red, pixel.green, pixel.blue) && skinPalette.isNotEmpty) {
      // For skin tones, search in skin palette first
      final pixelLab = rgbToLabCached(pixel.red, pixel.green, pixel.blue);
      double minDist = double.infinity;
      BeadColor closest = skinPalette.first;

      for (final bead in skinPalette) {
        final beadLab = rgbToLabCached(bead.r, bead.g, bead.b);
        final dist = deltaE2000(pixelLab, beadLab);
        if (dist < minDist) {
          minDist = dist;
          closest = bead;
        }
      }

      // If skin palette match is good enough, use it
      if (minDist < 15) return closest;
    }

    return findClosest(pixel, palette);
  }

  /// Extract skin-tone colors from a palette
  static List<BeadColor> extractSkinColors(List<BeadColor> palette) {
    return palette.where((c) => isSkinTone(c.r, c.g, c.b)).toList();
  }

  void clearCache() {
    _cache.clear();
    _labCache.clear();
  }
}
