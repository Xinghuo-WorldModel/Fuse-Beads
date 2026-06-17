import 'package:flutter/material.dart';

class BeadColor {
  final String code;
  final String name;
  final String hex;
  final Color color;

  BeadColor({
    required this.code,
    required this.name,
    required this.hex,
  }) : color = _hexToColor(hex);

  static Color _hexToColor(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 7) buffer.write('FF');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  factory BeadColor.fromJson(Map<String, dynamic> json) {
    return BeadColor(
      code: json['code'] as String,
      name: json['name'] as String,
      hex: json['hex'] as String,
    );
  }

  int get r => color.red;
  int get g => color.green;
  int get b => color.blue;
}
