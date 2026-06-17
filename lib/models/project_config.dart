import 'bead_brand.dart';

enum ConvertMode {
  pixel,
  realistic,
}

class GridSize {
  final int width;
  final int height;
  final String label;

  const GridSize({required this.width, required this.height, required this.label});

  static const List<GridSize> presets = [
    GridSize(width: 29, height: 29, label: '小型 29×29（单板）'),
    GridSize(width: 58, height: 58, label: '中型 58×58（四板）'),
    GridSize(width: 87, height: 87, label: '大型 87×87（九板）'),
    GridSize(width: 116, height: 116, label: '超大 116×116（十六板）'),
    GridSize(width: 145, height: 145, label: '巨幅 145×145（二十五板）'),
  ];
}

class ProjectConfig {
  final ConvertMode mode;
  final BeadBrand brand;
  final GridSize gridSize;
  final int maxColors;

  const ProjectConfig({
    required this.mode,
    required this.brand,
    required this.gridSize,
    this.maxColors = 50,
  });

  ProjectConfig copyWith({
    ConvertMode? mode,
    BeadBrand? brand,
    GridSize? gridSize,
    int? maxColors,
  }) {
    return ProjectConfig(
      mode: mode ?? this.mode,
      brand: brand ?? this.brand,
      gridSize: gridSize ?? this.gridSize,
      maxColors: maxColors ?? this.maxColors,
    );
  }
}
