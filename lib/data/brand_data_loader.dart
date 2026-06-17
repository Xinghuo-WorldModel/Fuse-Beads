import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/bead_color.dart';
import '../models/bead_brand.dart';

class BrandDataLoader {
  /// All supported brands: (file id, display name)
  static const List<MapEntry<String, String>> brandList = [
    MapEntry('artkal', 'Artkal S'),
    MapEntry('artkal_r', 'Artkal R'),
    MapEntry('perler', 'Perler'),
    MapEntry('hama', 'Hama'),
    MapEntry('mard', 'MARD'),
    MapEntry('yant', 'Yant'),
    MapEntry('nabbi', 'Nabbi'),
  ];

  static Future<BeadBrand> loadBrand(String brandId, String name) async {
    final jsonStr = await rootBundle.loadString('assets/brand_colors/$brandId.json');
    final List<dynamic> jsonList = json.decode(jsonStr);
    final colors = jsonList
        .map((e) => BeadColor.fromJson(e as Map<String, dynamic>))
        .toList();
    return BeadBrand(id: brandId, name: name, colors: colors);
  }

  static Future<List<BeadBrand>> loadAllBrands() async {
    final brands = <BeadBrand>[];
    for (final entry in brandList) {
      try {
        brands.add(await loadBrand(entry.key, entry.value));
      } catch (_) {
        // Skip brands that fail to load
      }
    }
    return brands;
  }
}
