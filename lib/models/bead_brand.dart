import 'bead_color.dart';

class BeadBrand {
  final String id;
  final String name;
  final List<BeadColor> colors;

  const BeadBrand({
    required this.id,
    required this.name,
    required this.colors,
  });

  int get colorCount => colors.length;
}
