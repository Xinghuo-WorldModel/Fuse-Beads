import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import '../models/bead_color.dart';
import '../models/project_config.dart';
import 'pixel_converter.dart';

class ImageProcessor {
  final ImagePicker _picker = ImagePicker();

  Future<XFile?> pickImage({required ImageSource source}) async {
    return await _picker.pickImage(
      source: source,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 95,
    );
  }

  /// Calculate actual grid size preserving image aspect ratio
  GridSize computeActualGridSize(int imgWidth, int imgHeight, GridSize target) {
    final imgRatio = imgWidth / imgHeight;

    int w, h;
    if (imgRatio >= 1.0) {
      w = target.width;
      h = (w / imgRatio).round().clamp(1, 500);
    } else {
      h = target.height;
      w = (h * imgRatio).round().clamp(1, 500);
    }

    return GridSize(width: w, height: h, label: '$w×$h');
  }

  Future<ConvertResult?> processAndConvert(
    Uint8List imageBytes,
    ProjectConfig config,
  ) async {
    // Run heavy image processing in a separate isolate
    final result = await compute(
      _processInIsolate,
      _ProcessParams(
        imageBytes: imageBytes,
        mode: config.mode,
        brandColors: config.brand.colors
            .map((c) => _SerializableColor(
                  code: c.code, name: c.name, hex: c.hex))
            .toList(),
        gridWidth: config.gridSize.width,
        gridHeight: config.gridSize.height,
        maxColors: config.maxColors,
      ),
    );
    return result;
  }
}

class _SerializableColor {
  final String code;
  final String name;
  final String hex;
  _SerializableColor({
    required this.code, required this.name, required this.hex,
  });
}

class _ProcessParams {
  final Uint8List imageBytes;
  final ConvertMode mode;
  final List<_SerializableColor> brandColors;
  final int gridWidth;
  final int gridHeight;
  final int maxColors;

  _ProcessParams({
    required this.imageBytes,
    required this.mode,
    required this.brandColors,
    required this.gridWidth,
    required this.gridHeight,
    required this.maxColors,
  });
}

/// Top-level function for isolate execution
ConvertResult? _processInIsolate(_ProcessParams params) {
  final original = img.decodeImage(params.imageBytes);
  if (original == null) return null;

  // Rebuild BeadColor list from serializable data
  final palette = params.brandColors
      .map((c) => BeadColor(code: c.code, name: c.name, hex: c.hex))
      .toList();

  // Compute actual grid size
  final imgRatio = original.width / original.height;
  int w, h;
  if (imgRatio >= 1.0) {
    w = params.gridWidth;
    h = (w / imgRatio).round().clamp(1, 500);
  } else {
    h = params.gridHeight;
    w = (h * imgRatio).round().clamp(1, 500);
  }
  final actualGrid = GridSize(width: w, height: h, label: '$w×$h');

  final converter = PixelConverter();

  switch (params.mode) {
    case ConvertMode.pixel:
      return converter.convertPixelStyle(
        original, palette, actualGrid,
        maxColors: params.maxColors,
      );
    case ConvertMode.realistic:
      return converter.convertRealisticStyle(
        original, palette, actualGrid,
        maxColors: params.maxColors,
      );
  }
}
