import 'package:flutter/material.dart';
import '../models/bead_color.dart';
import '../models/project_config.dart';
import '../services/pixel_converter.dart';
import '../services/export_service.dart';
import '../services/file_saver.dart';
import '../widgets/bead_grid_painter.dart';
import '../widgets/color_palette_widget.dart';
import '../widgets/color_picker_sheet.dart';

class PreviewScreen extends StatefulWidget {
  final ConvertResult result;
  final ProjectConfig config;

  const PreviewScreen({super.key, required this.result, required this.config});

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  final TransformationController _transformController = TransformationController();
  bool _showCodes = true;
  bool _showPalette = false;
  bool _editMode = false;
  bool _exporting = false;
  int _revision = 0;
  String? _tappedInfo;
  bool _initialized = false;
  Size _viewportSize = Size.zero;

  static const double _cell = 20;
  static const double _minimapSize = 120;

  @override
  void initState() {
    super.initState();
    _transformController.addListener(_onTransformChanged);
  }

  @override
  void dispose() {
    _transformController.removeListener(_onTransformChanged);
    _transformController.dispose();
    super.dispose();
  }

  void _onTransformChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('预览'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_showCodes ? Icons.numbers : Icons.numbers_outlined),
            tooltip: '显示/隐藏色号',
            onPressed: () => setState(() => _showCodes = !_showCodes),
          ),
          IconButton(
            icon: const Icon(Icons.palette_outlined),
            tooltip: '用色统计',
            onPressed: () => setState(() => _showPalette = !_showPalette),
          ),
          IconButton(
            icon: const Icon(Icons.save_alt),
            tooltip: '导出图片',
            onPressed: _exporting ? null : _exportImage,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => setState(() {
          _editMode = !_editMode;
          _tappedInfo = _editMode ? '编辑模式：点击格子修改颜色' : null;
        }),
        icon: Icon(_editMode ? Icons.check : Icons.edit),
        label: Text(_editMode ? '完成' : '编辑颜色'),
        backgroundColor: _editMode ? theme.colorScheme.tertiary : null,
      ),
      body: Column(
        children: [
          if (_tappedInfo != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: _editMode
                  ? theme.colorScheme.tertiaryContainer
                  : theme.colorScheme.primaryContainer,
              child: Text(
                _tappedInfo!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: _editMode
                      ? theme.colorScheme.onTertiaryContainer
                      : theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          Expanded(
            flex: _showPalette ? 3 : 1,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final gridW = widget.result.width * _cell;
                final gridH = widget.result.height * _cell;
                _viewportSize = Size(constraints.maxWidth, constraints.maxHeight);

                if (!_initialized && constraints.maxWidth > 0) {
                  _initialized = true;
                  final scaleX = constraints.maxWidth / gridW;
                  final scaleY = constraints.maxHeight / gridH;
                  final fitScale = scaleX < scaleY ? scaleX : scaleY;
                  final clampedScale = fitScale.clamp(0.3, 3.0);

                  final dx = (constraints.maxWidth - gridW * clampedScale) / 2;
                  final dy = (constraints.maxHeight - gridH * clampedScale) / 2;

                  _transformController.value = Matrix4.identity()
                    ..translate(dx > 0 ? dx : 0.0, dy > 0 ? dy : 0.0)
                    ..scale(clampedScale);
                }

                return Stack(
                  children: [
                    GestureDetector(
                      onTapDown: _onGridTap,
                      child: InteractiveViewer(
                        transformationController: _transformController,
                        minScale: 0.1,
                        maxScale: 10.0,
                        constrained: false,
                        boundaryMargin: const EdgeInsets.all(double.infinity),
                        child: CustomPaint(
                          size: Size(gridW, gridH),
                          painter: BeadGridPainter(
                            result: widget.result,
                            showCodes: _showCodes,
                            cellSize: _cell,
                            revision: _revision,
                          ),
                        ),
                      ),
                    ),
                    // Minimap navigator
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: _buildMinimap(gridW, gridH, theme),
                    ),
                    // Zoom controls
                    Positioned(
                      right: 12,
                      top: 12,
                      child: _buildZoomControls(theme, gridW, gridH),
                    ),
                  ],
                );
              },
            ),
          ),
          if (_showPalette)
            Expanded(
              flex: 2,
              child: ColorPaletteWidget(
                key: ValueKey(_revision),
                colorUsage: widget.result.colorUsage,
                palette: widget.config.brand.colors,
              ),
            ),
        ],
      ),
    );
  }

  void _onGridTap(TapDownDetails details) {
    final inverseMatrix = Matrix4.inverted(_transformController.value);
    final localPoint = MatrixUtils.transformPoint(
      inverseMatrix,
      details.localPosition,
    );

    final cellX = (localPoint.dx / _cell).floor();
    final cellY = (localPoint.dy / _cell).floor();

    if (cellX < 0 ||
        cellX >= widget.result.width ||
        cellY < 0 ||
        cellY >= widget.result.height) {
      return;
    }

    final cell = widget.result.grid[cellY][cellX];

    if (_editMode) {
      _pickColorForCell(cellX, cellY, cell.beadColor);
    } else {
      setState(() {
        _tappedInfo = '位置 ($cellX, $cellY) - ${cell.beadColor.code} ${cell.beadColor.name}';
      });
    }
  }

  Future<void> _pickColorForCell(int x, int y, BeadColor current) async {
    final picked = await showModalBottomSheet<BeadColor>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ColorPickerSheet(
        palette: widget.config.brand.colors,
        current: current,
      ),
    );

    if (picked != null) {
      setState(() {
        widget.result.setCellColor(x, y, picked);
        _revision++;
        _tappedInfo = '已将 ($x, $y) 改为 ${picked.code} ${picked.name}';
      });
    }
  }

  Widget _buildMinimap(double gridW, double gridH, ThemeData theme) {
    final gridRatio = gridW / gridH;
    double mapW, mapH;
    if (gridRatio >= 1) {
      mapW = _minimapSize;
      mapH = _minimapSize / gridRatio;
    } else {
      mapH = _minimapSize;
      mapW = _minimapSize * gridRatio;
    }

    // Calculate viewport rect on minimap
    final matrix = _transformController.value;
    final scale = matrix.storage[0]; // scaleX from matrix
    final tx = matrix.storage[12];   // translateX
    final ty = matrix.storage[13];   // translateY

    final visibleLeft = -tx / scale;
    final visibleTop = -ty / scale;
    final visibleW = _viewportSize.width / scale;
    final visibleH = _viewportSize.height / scale;

    final rectLeft = (visibleLeft / gridW * mapW).clamp(0.0, mapW);
    final rectTop = (visibleTop / gridH * mapH).clamp(0.0, mapH);
    final rectW = (visibleW / gridW * mapW).clamp(4.0, mapW - rectLeft);
    final rectH = (visibleH / gridH * mapH).clamp(4.0, mapH - rectTop);

    return GestureDetector(
      onPanUpdate: (details) => _onMinimapDrag(details, gridW, gridH, mapW, mapH),
      onTapDown: (details) => _onMinimapTap(details, gridW, gridH, mapW, mapH),
      child: Container(
        width: mapW,
        height: mapH,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withOpacity(0.9),
          border: Border.all(color: theme.colorScheme.outline, width: 1),
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: Stack(
            children: [
              RepaintBoundary(
                child: CustomPaint(
                  size: Size(mapW, mapH),
                  painter: _MinimapPainter(
                    result: widget.result,
                    revision: _revision,
                  ),
                ),
              ),
              Positioned(
                left: rectLeft,
                top: rectTop,
                child: Container(
                  width: rectW,
                  height: rectH,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: theme.colorScheme.primary,
                      width: 2,
                    ),
                    color: theme.colorScheme.primary.withOpacity(0.1),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onMinimapDrag(DragUpdateDetails details, double gridW, double gridH, double mapW, double mapH) {
    final dx = details.delta.dx / mapW * gridW;
    final dy = details.delta.dy / mapH * gridH;
    final scale = _transformController.value.storage[0];
    final tx = _transformController.value.storage[12] - dx * scale;
    final ty = _transformController.value.storage[13] - dy * scale;
    _transformController.value = Matrix4.identity()
      ..translate(tx, ty)
      ..scale(scale);
  }

  void _onMinimapTap(TapDownDetails details, double gridW, double gridH, double mapW, double mapH) {
    final tapX = details.localPosition.dx / mapW * gridW;
    final tapY = details.localPosition.dy / mapH * gridH;
    final scale = _transformController.value.storage[0];

    final newTx = -tapX * scale + _viewportSize.width / 2;
    final newTy = -tapY * scale + _viewportSize.height / 2;

    _transformController.value = Matrix4.identity()
      ..translate(newTx, newTy)
      ..scale(scale);
  }

  Widget _buildZoomControls(ThemeData theme, double gridW, double gridH) {
    final scale = _transformController.value.storage[0];
    final percent = (scale * 100).round();

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '放大',
            onPressed: () => _zoom(1.3, gridW, gridH),
            iconSize: 20,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '$percent%',
              style: theme.textTheme.labelSmall,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove),
            tooltip: '缩小',
            onPressed: () => _zoom(0.7, gridW, gridH),
            iconSize: 20,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          const Divider(height: 1),
          IconButton(
            icon: const Icon(Icons.fit_screen),
            tooltip: '适应屏幕',
            onPressed: () => _fitToScreen(gridW, gridH),
            iconSize: 20,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }

  void _zoom(double factor, double gridW, double gridH) {
    final currentScale = _transformController.value.storage[0];
    final newScale = (currentScale * factor).clamp(0.1, 10.0);
    final tx = _transformController.value.storage[12];
    final ty = _transformController.value.storage[13];

    // Zoom toward center of viewport
    final centerX = _viewportSize.width / 2;
    final centerY = _viewportSize.height / 2;

    final focalX = (centerX - tx) / currentScale;
    final focalY = (centerY - ty) / currentScale;

    final newTx = centerX - focalX * newScale;
    final newTy = centerY - focalY * newScale;

    _transformController.value = Matrix4.identity()
      ..translate(newTx, newTy)
      ..scale(newScale);
  }

  void _fitToScreen(double gridW, double gridH) {
    final scaleX = _viewportSize.width / gridW;
    final scaleY = _viewportSize.height / gridH;
    final fitScale = (scaleX < scaleY ? scaleX : scaleY).clamp(0.1, 3.0);

    final dx = (_viewportSize.width - gridW * fitScale) / 2;
    final dy = (_viewportSize.height - gridH * fitScale) / 2;

    _transformController.value = Matrix4.identity()
      ..translate(dx > 0 ? dx : 0.0, dy > 0 ? dy : 0.0)
      ..scale(fitScale);
  }

  Future<void> _exportImage() async {
    setState(() => _exporting = true);
    try {
      final exportService = ExportService();
      final bytes = await exportService.exportToBytes(
        widget.result,
        widget.config,
      );

      if (!mounted) return;

      final now = DateTime.now();
      final filename = '酥豆_${now.year}'
          '${now.month.toString().padLeft(2, '0')}'
          '${now.day.toString().padLeft(2, '0')}_'
          '${now.hour.toString().padLeft(2, '0')}'
          '${now.minute.toString().padLeft(2, '0')}'
          '${now.second.toString().padLeft(2, '0')}.png';

      final msg = await saveFileToDownloads(bytes, filename);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }
}

/// Lightweight minimap painter - draws colored blocks without text
class _MinimapPainter extends CustomPainter {
  final ConvertResult result;
  final int revision;

  _MinimapPainter({required this.result, required this.revision});

  @override
  void paint(Canvas canvas, Size size) {
    final cellW = size.width / result.width;
    final cellH = size.height / result.height;
    final paint = Paint()..style = PaintingStyle.fill;

    for (int y = 0; y < result.height; y++) {
      for (int x = 0; x < result.width; x++) {
        final bead = result.grid[y][x].beadColor;
        paint.color = bead.color;
        canvas.drawRect(
          Rect.fromLTWH(x * cellW, y * cellH, cellW + 0.5, cellH + 0.5),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_MinimapPainter old) => old.revision != revision;
}
