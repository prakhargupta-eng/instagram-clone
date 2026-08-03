import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart' as video;

import '../../constants.dart';
import '../../widgets/media_image.dart';

class PostEditorScreen extends StatefulWidget {
  const PostEditorScreen({
    super.key,
    required this.mediaUrl,
    required this.isVideo,
  });

  final String mediaUrl;
  final bool isVideo;

  @override
  State<PostEditorScreen> createState() => _PostEditorScreenState();
}

class _PostEditorScreenState extends State<PostEditorScreen> {
  int _filterIndex = 0;
  bool _cropMode = false;
  double? _aspect;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: AppColors.white,
        title: const Text('Edit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(widget.mediaUrl),
            child: const Text(
              AppStrings.next,
              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: _aspect ?? 1,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColorFiltered(
                      colorFilter: _filters[_filterIndex].matrix,
                      child: _MediaPreview(url: widget.mediaUrl, isVideo: widget.isVideo),
                    ),
                    if (_cropMode) _CropBox(aspect: _aspect),
                  ],
                ),
              ),
            ),
          ),
          _buildModeBar(),
          _cropMode ? _buildCropPanel() : _buildFilterStrip(),
        ],
      ),
    );
  }

  Widget _buildModeBar() {
    return Container(
      color: const Color(0xFF161616),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _ModeButton(
            icon: Icons.tune,
            label: 'Filters',
            selected: !_cropMode,
            onTap: () => setState(() => _cropMode = false),
          ),
          const SizedBox(width: 32),
          _ModeButton(
            icon: Icons.crop,
            label: 'Crop',
            selected: _cropMode,
            onTap: () => setState(() => _cropMode = true),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterStrip() {
    return Container(
      height: 104,
      color: const Color(0xFF161616),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          return GestureDetector(
            onTap: () => setState(() => _filterIndex = index),
            child: Container(
              width: 68,
              margin: const EdgeInsets.symmetric(horizontal: 5),
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: _filterIndex == index ? AppColors.white : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: ColorFiltered(
                          colorFilter: filter.matrix,
                          child: MediaImage(
                            path: widget.mediaUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              color: Colors.black26,
                              child: const Icon(Icons.broken_image_outlined, color: Colors.white38),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    filter.name,
                    style: TextStyle(
                      color: _filterIndex == index ? AppColors.white : Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCropPanel() {
    return Container(
      color: const Color(0xFF161616),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final (label, aspect) in _aspectOptions)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Text(label, style: const TextStyle(fontSize: 12)),
                selected: _aspect == aspect,
                onSelected: (_) => setState(() => _aspect = aspect),
                selectedColor: AppColors.primary,
                backgroundColor: const Color(0xFF2A2A2A),
                labelStyle: TextStyle(
                  color: _aspect == aspect ? AppColors.white : Colors.white70,
                  fontSize: 12,
                ),
                side: BorderSide.none,
              ),
            ),
        ],
      ),
    );
  }

  static const _aspectOptions = <(String, double?)>[
    ('Original', null),
    ('1:1', 1),
    ('4:5', 4 / 5),
    ('16:9', 16 / 9),
  ];
}

class _MediaPreview extends StatefulWidget {
  const _MediaPreview({required this.url, required this.isVideo});

  final String url;
  final bool isVideo;

  @override
  State<_MediaPreview> createState() => _MediaPreviewState();
}

class _MediaPreviewState extends State<_MediaPreview> {
  video.VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    if (widget.isVideo) {
      _controller = video.VideoPlayerController.networkUrl(Uri.parse(widget.url))
        ..initialize().then((_) {
          if (!mounted) return;
          _controller?.setLooping(true);
          _controller?.setVolume(0);
          _controller?.play();
          setState(() {});
        }).catchError((_) {
          if (!mounted) return;
          setState(() {});
        });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isVideo) {
      final c = _controller;
      if (c == null || !c.value.isInitialized) {
        return Container(
          color: Colors.black,
          alignment: Alignment.center,
          child: const CircularProgressIndicator(color: Colors.white54),
        );
      }
      return video.VideoPlayer(c);
    }
    return MediaImage(
      path: widget.url,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Container(
        color: Colors.black26,
        alignment: Alignment.center,
        child: const Icon(Icons.broken_image_outlined, color: Colors.white38, size: 48),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: selected ? AppColors.white : Colors.white54, size: 22),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.white : Colors.white54,
              fontSize: 11,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _CropBox extends StatefulWidget {
  const _CropBox({required this.aspect});

  final double? aspect;

  @override
  State<_CropBox> createState() => _CropBoxState();
}

class _CropBoxState extends State<_CropBox> {
  Rect _rect = const Rect.fromLTRB(0.1, 0.1, 0.9, 0.9);
  int? _dragHandle;

  static const double _minSize = 0.2;
  static const double _handleRadius = 14;

  @override
  void didUpdateWidget(_CropBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.aspect != widget.aspect) _applyAspect();
  }

  void _applyAspect() {
    final a = widget.aspect;
    if (a == null) return;
    var w = _rect.width;
    var h = w / a;
    if (h > 1) {
      h = 1;
      w = a * h;
    }
    final center = _rect.center;
    final rect = Rect.fromCenter(center: center, width: w, height: h);
    setState(() => _rect = _clamp(rect));
  }

  Rect _clamp(Rect r) {
    return Rect.fromLTRB(
      r.left.clamp(0.0, 1.0 - _minSize),
      r.top.clamp(0.0, 1.0 - _minSize),
      r.right.clamp(_minSize, 1.0),
      r.bottom.clamp(_minSize, 1.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final abs = Rect.fromLTRB(
          _rect.left * size.width,
          _rect.top * size.height,
          _rect.right * size.width,
          _rect.bottom * size.height,
        );
        return GestureDetector(
          onPanStart: (d) => _onPanStart(d.localPosition, size),
          onPanUpdate: (d) => _onPanUpdate(d.delta, size),
          onPanEnd: (_) => _dragHandle = null,
          child: CustomPaint(
            size: size,
            painter: _CropPainter(cropRect: abs, handleRadius: _handleRadius),
          ),
        );
      },
    );
  }

  void _onPanStart(Offset position, Size size) {
    final abs = _localRect(size);
    const tol = 20.0;
    final handles = [
      abs.topLeft,
      abs.topRight,
      abs.bottomRight,
      abs.bottomLeft,
    ];
    for (var i = 0; i < handles.length; i++) {
      if ((position - handles[i]).distance <= tol) {
        _dragHandle = i;
        return;
      }
    }
    if (abs.contains(position)) {
      _dragHandle = 4;
    } else {
      _dragHandle = null;
    }
  }

  void _onPanUpdate(Offset delta, Size size) {
    if (_dragHandle == null) return;
    final dx = delta.dx / size.width;
    final dy = delta.dy / size.height;
    setState(() {
      switch (_dragHandle) {
        case 0:
          _rect = _clamp(Rect.fromLTRB(_rect.left + dx, _rect.top + dy, _rect.right, _rect.bottom));
        case 1:
          _rect = _clamp(Rect.fromLTRB(_rect.left, _rect.top + dy, _rect.right + dx, _rect.bottom));
        case 2:
          _rect = _clamp(Rect.fromLTRB(_rect.left, _rect.top, _rect.right + dx, _rect.bottom + dy));
        case 3:
          _rect = _clamp(Rect.fromLTRB(_rect.left + dx, _rect.top, _rect.right, _rect.bottom + dy));
        case 4:
          final r = _rect.shift(Offset(dx, dy));
          if (r.left >= 0 && r.top >= 0 && r.right <= 1 && r.bottom <= 1) {
            _rect = r;
          }
      }
    });
  }

  Rect _localRect(Size size) => Rect.fromLTRB(
        _rect.left * size.width,
        _rect.top * size.height,
        _rect.right * size.width,
        _rect.bottom * size.height,
      );
}

class _CropPainter extends CustomPainter {
  _CropPainter({required this.cropRect, required this.handleRadius});

  final Rect cropRect;
  final double handleRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final scrim = Paint()..color = Colors.black.withValues(alpha: 0.55);

    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRect(cropRect);
    canvas.drawPath(path, scrim);

    final grid = Paint()
      ..color = Colors.white54
      ..strokeWidth = 0.8;
    for (var i = 1; i < 3; i++) {
      final x = cropRect.left + cropRect.width * i / 3;
      final y = cropRect.top + cropRect.height * i / 3;
      canvas.drawLine(Offset(x, cropRect.top), Offset(x, cropRect.bottom), grid);
      canvas.drawLine(Offset(cropRect.left, y), Offset(cropRect.right, y), grid);
    }

    final border = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.4;
    canvas.drawRect(cropRect, border);

    final handlePaint = Paint()..color = Colors.white;
    for (final corner in [
      cropRect.topLeft,
      cropRect.topRight,
      cropRect.bottomRight,
      cropRect.bottomLeft,
    ]) {
      canvas.drawCircle(corner, handleRadius, handlePaint);
      canvas.drawCircle(
        corner,
        handleRadius,
        Paint()..color = Colors.black.withValues(alpha: 0.15)..style = PaintingStyle.stroke..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(_CropPainter oldDelegate) =>
      oldDelegate.cropRect != cropRect || oldDelegate.handleRadius != handleRadius;
}

class FilterPreset {
  const FilterPreset(this.name, this.matrix);

  final String name;
  final ColorFilter matrix;
}

final _filters = <FilterPreset>[
  const FilterPreset('Normal', ColorFilter.matrix([
    1, 0, 0, 0, 0,
    0, 1, 0, 0, 0,
    0, 0, 1, 0, 0,
    0, 0, 0, 1, 0,
  ])),
  const FilterPreset('Clarendon', ColorFilter.matrix([
    1.25, 0, 0, 0, -18,
    0, 1.25, 0, 0, -18,
    0, 0, 1.25, 0, -28,
    0, 0, 0, 1, 0,
  ])),
  const FilterPreset('Gingham', ColorFilter.matrix([
    0.86, 0.07, 0.07, 0, 0,
    0.07, 0.86, 0.07, 0, 0,
    0.07, 0.07, 0.86, 0, 0,
    0, 0, 0, 1, 0,
  ])),
  const FilterPreset('Moon', ColorFilter.matrix([
    0.21, 0.72, 0.07, 0, 40,
    0.21, 0.72, 0.07, 0, 40,
    0.21, 0.72, 0.07, 0, 40,
    0, 0, 0, 1, 0,
  ])),
  const FilterPreset('Lark', ColorFilter.matrix([
    1.1, 0, 0, 0, 15,
    0, 1.05, 0, 0, 15,
    0, 0, 1.0, 0, 20,
    0, 0, 0, 1, 0,
  ])),
  const FilterPreset('Reyes', ColorFilter.matrix([
    1.2, 0, 0, 0, 0,
    0, 1.05, 0, 0, 0,
    0, 0, 0.9, 0, 0,
    0, 0, 0, 1, 0,
  ])),
  const FilterPreset('Juno', ColorFilter.matrix([
    1.4, 0, 0, 0, -15,
    0, 1.2, 0, 0, -10,
    0, 0, 1.1, 0, -10,
    0, 0, 0, 1, 0,
  ])),
  const FilterPreset('Willow', ColorFilter.matrix([
    0.5, 0.5, 0, 0, 20,
    0.35, 0.65, 0, 0, 15,
    0.4, 0.4, 0.2, 0, 10,
    0, 0, 0, 1, 0,
  ])),
];
