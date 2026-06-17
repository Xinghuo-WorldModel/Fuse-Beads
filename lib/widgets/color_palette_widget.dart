import 'package:flutter/material.dart';
import '../models/bead_color.dart';

class ColorPaletteWidget extends StatelessWidget {
  final Map<String, int> colorUsage;
  final List<BeadColor> palette;
  final Function(BeadColor)? onColorTap;

  const ColorPaletteWidget({
    super.key,
    required this.colorUsage,
    required this.palette,
    this.onColorTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sortedEntries = colorUsage.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final totalBeads = colorUsage.values.fold(0, (sum, v) => sum + v);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            '用色统计 (${colorUsage.length} 种颜色, 共 $totalBeads 颗)',
            style: theme.textTheme.titleSmall,
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: sortedEntries.length,
            itemBuilder: (context, index) {
              final entry = sortedEntries[index];
              final bead = palette.firstWhere(
                (c) => c.code == entry.key,
                orElse: () => BeadColor(
                  code: entry.key,
                  name: '未知',
                  hex: '#CCCCCC',
                ),
              );
              final percent = totalBeads == 0
                  ? '0.0'
                  : (entry.value / totalBeads * 100).toStringAsFixed(1);

              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: bead.color,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.black12),
                  ),
                ),
                title: Text('${bead.code} - ${bead.name}'),
                trailing: Text('${entry.value} ($percent%)'),
                onTap: onColorTap != null ? () => onColorTap!(bead) : null,
              );
            },
          ),
        ),
      ],
    );
  }
}
