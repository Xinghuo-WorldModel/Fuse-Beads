import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/bead_brand.dart';
import '../models/project_config.dart';
import '../data/brand_data_loader.dart';
import '../services/image_processor.dart';
import 'preview_screen.dart';

class ConfigScreen extends StatefulWidget {
  final ConvertMode mode;

  const ConfigScreen({super.key, required this.mode});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  List<BeadBrand>? _brands;
  BeadBrand? _selectedBrand;
  GridSize _selectedSize = GridSize.presets[1]; // Default to medium
  int _maxColors = 50;
  bool _useCustomSize = false;
  final _customWidthController = TextEditingController(text: '60');
  final _customHeightController = TextEditingController(text: '60');
  bool _loading = true;
  bool _processing = false;
  Uint8List? _imageBytes;

  @override
  void initState() {
    super.initState();
    _loadBrands();
  }

  Future<void> _loadBrands() async {
    final brands = await BrandDataLoader.loadAllBrands();
    setState(() {
      _brands = brands;
      _selectedBrand = brands.first;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final modeName = widget.mode == ConvertMode.pixel ? '像素风格' : '写实拼豆';

    return Scaffold(
      appBar: AppBar(
        title: Text('$modeName - 配置'),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildImageSection(theme),
                  const SizedBox(height: 24),
                  _buildBrandSection(theme),
                  const SizedBox(height: 24),
                  _buildSizeSection(theme),
                  const SizedBox(height: 24),
                  _buildColorLimitSection(theme),
                  const SizedBox(height: 32),
                  _buildStartButton(theme),
                ],
              ),
            ),
    );
  }

  Widget _buildImageSection(ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      child: InkWell(
        onTap: _pickImage,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(minHeight: 150, maxHeight: 300),
          alignment: Alignment.center,
          child: _imageBytes != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    _imageBytes!,
                    fit: BoxFit.contain,
                    width: double.infinity,
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 48,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '点击选择人像照片',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildBrandSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('拼豆品牌', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        DropdownButtonFormField<BeadBrand>(
          value: _selectedBrand,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            isDense: true,
            prefixIcon: Icon(Icons.palette_outlined),
          ),
          items: _brands!
              .map((b) => DropdownMenuItem(
                    value: b,
                    child: Text('${b.name}（${b.colorCount} 色）'),
                  ))
              .toList(),
          onChanged: (b) {
            if (b == null) return;
            setState(() {
              _selectedBrand = b;
              if (_maxColors > _selectedBrand!.colorCount) {
                _maxColors = _selectedBrand!.colorCount;
              }
            });
          },
        ),
        const SizedBox(height: 8),
        Text(
          '${_selectedBrand!.name} 共 ${_selectedBrand!.colorCount} 种颜色',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildSizeSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('图案尺寸', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        ...GridSize.presets.map((size) => RadioListTile<GridSize>(
              title: Text(size.label),
              subtitle: Text('共 ${size.width * size.height} 颗豆'),
              value: size,
              groupValue: _useCustomSize ? null : _selectedSize,
              onChanged: (v) => setState(() {
                _selectedSize = v!;
                _useCustomSize = false;
              }),
              contentPadding: EdgeInsets.zero,
              dense: true,
            )),
        RadioListTile<bool>(
          title: const Text('自定义尺寸'),
          value: true,
          groupValue: _useCustomSize ? true : null,
          onChanged: (_) => setState(() => _useCustomSize = true),
          contentPadding: EdgeInsets.zero,
          dense: true,
        ),
        if (_useCustomSize)
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customWidthController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '宽',
                      suffixText: '格',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (_) => _updateCustomSize(),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('×'),
                ),
                Expanded(
                  child: TextField(
                    controller: _customHeightController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '高',
                      suffixText: '格',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (_) => _updateCustomSize(),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _updateCustomSize() {
    final w = int.tryParse(_customWidthController.text) ?? 60;
    final h = int.tryParse(_customHeightController.text) ?? 60;
    setState(() {
      _selectedSize = GridSize(
        width: w.clamp(10, 300),
        height: h.clamp(10, 300),
        label: '自定义 $w×$h',
      );
    });
  }

  Widget _buildColorLimitSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('最大颜色数', style: theme.textTheme.titleMedium),
            Text(
              '$_maxColors 色',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        Slider(
          value: _maxColors.toDouble(),
          min: 4,
          max: _selectedBrand!.colorCount.toDouble(),
          divisions: (_selectedBrand!.colorCount - 4),
          onChanged: (v) => setState(() => _maxColors = v.round()),
        ),
        Text(
          '颜色越少越容易制作，但细节会减少',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildStartButton(ThemeData theme) {
    return FilledButton.icon(
      onPressed: _imageBytes == null || _processing ? null : _startProcessing,
      icon: _processing
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : const Icon(Icons.auto_fix_high),
      label: Text(_processing ? '处理中...' : '开始转换'),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: theme.textTheme.titleMedium,
      ),
    );
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('拍照'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('从相册选择'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final processor = ImageProcessor();
      final file = await processor.pickImage(source: source);
      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() {
          _imageBytes = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('permission')
                  ? '需要相机/存储权限，请在系统设置中开启'
                  : '选取图片失败: $e',
            ),
            action: SnackBarAction(label: '知道了', onPressed: () {}),
          ),
        );
      }
    }
  }

  Future<void> _startProcessing() async {
    if (_imageBytes == null || _selectedBrand == null) return;

    setState(() => _processing = true);

    try {
      final config = ProjectConfig(
        mode: widget.mode,
        brand: _selectedBrand!,
        gridSize: _selectedSize,
        maxColors: _maxColors,
      );

      final processor = ImageProcessor();
      final result = await processor.processAndConvert(_imageBytes!, config);

      if (result != null && mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PreviewScreen(result: result, config: config),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('处理失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }
}
