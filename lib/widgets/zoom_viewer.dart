import 'package:flutter/material.dart';

class ZoomViewer extends StatefulWidget {
  final Widget child;
  final double minScale;
  final double maxScale;

  const ZoomViewer({
    super.key,
    required this.child,
    this.minScale = 0.5,
    this.maxScale = 8.0,
  });

  @override
  State<ZoomViewer> createState() => _ZoomViewerState();
}

class _ZoomViewerState extends State<ZoomViewer> {
  final TransformationController _controller = TransformationController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _resetZoom() {
    _controller.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        InteractiveViewer(
          transformationController: _controller,
          minScale: widget.minScale,
          maxScale: widget.maxScale,
          constrained: false,
          child: widget.child,
        ),
        Positioned(
          right: 8,
          bottom: 8,
          child: FloatingActionButton.small(
            onPressed: _resetZoom,
            child: const Icon(Icons.fit_screen),
          ),
        ),
      ],
    );
  }
}
