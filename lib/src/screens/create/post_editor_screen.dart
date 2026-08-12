import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:instagram_clone/src/compontes/ToastHelper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart' as video;
import 'package:get_thumbnail_video/video_thumbnail.dart';
import 'package:get_thumbnail_video/index.dart';

import '../../adaptive_colors.dart';
import '../../constants.dart';
import '../../services/local_post_store.dart';
import '../../widgets/media_image.dart';

class PostEditorScreen extends StatefulWidget {
  const PostEditorScreen({
    super.key,
    required this.mediaUrl,
    required this.isVideo,
    this.thumbnailUrl,
  });

  final String mediaUrl;
  final bool isVideo;
  final String? thumbnailUrl;

  @override
  State<PostEditorScreen> createState() => _PostEditorScreenState();
}

class _PostEditorScreenState extends State<PostEditorScreen> {
  double? _imageAspectRatio;
  String? _thumbnailPath;

  @override
  void initState() {
    super.initState();
    if (!widget.isVideo) {
      _loadImageAspectRatio();
    } else {
      _loadVideoThumbnail();
    }
  }

  Future<void> _loadVideoThumbnail() async {
    if (widget.thumbnailUrl != null &&
        widget.thumbnailUrl!.startsWith('http') &&
        !widget.thumbnailUrl!.contains('picsum.photos')) {
      if (mounted) {
        setState(() {
          _thumbnailPath = widget.thumbnailUrl;
        });
      }
      return;
    }
    try {
      final tempDir = await getTemporaryDirectory();
      final xFile = await VideoThumbnail.thumbnailFile(
        video: widget.mediaUrl,
        thumbnailPath: tempDir.path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 200,
        quality: 50,
      );
      if (mounted) {
        setState(() {
          _thumbnailPath = xFile.path;
        });
      }
    } catch (e) {
      debugPrint('Error generating thumbnail in editor: $e');
      if (mounted) {
        setState(() {
          _thumbnailPath = widget.thumbnailUrl;
        });
      }
    }
  }

  Future<void> _loadImageAspectRatio() async {
    try {
      final bytes = await File(widget.mediaUrl).readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      if (mounted) {
        setState(() {
          _imageAspectRatio = image.width / image.height;
        });
      }
    } catch (_) {}
  }

  int _filterIndex = 0;
  int _editorMode = 0; // 0 = Filter, 1 = Edit, 2 = Crop
  double? _aspect;
  Rect _normalizedCropRect = const Rect.fromLTRB(0.0, 0.0, 1.0, 1.0);
  bool _isProcessing = false;

  double _brightness = 0.0;
  double _contrast = 1.0;
  double _saturation = 1.0;

  String? _selectedAdjustment; // 'Brightness', 'Contrast', 'Saturation'
  double _tempVal = 0.0;

  List<double> _brightnessMatrix(double value) {
    final translation = value * 255.0;
    return [
      1,
      0,
      0,
      0,
      translation,
      0,
      1,
      0,
      0,
      translation,
      0,
      0,
      1,
      0,
      translation,
      0,
      0,
      0,
      1,
      0,
    ];
  }

  List<double> _contrastMatrix(double value) {
    final scale = value;
    final translate = 128.0 * (1.0 - scale);
    return [
      scale,
      0,
      0,
      0,
      translate,
      0,
      scale,
      0,
      0,
      translate,
      0,
      0,
      scale,
      0,
      translate,
      0,
      0,
      0,
      1,
      0,
    ];
  }

  List<double> _saturationMatrix(double value) {
    final invSat = 1.0 - value;
    final r = 0.213 * invSat;
    final g = 0.715 * invSat;
    final b = 0.072 * invSat;
    return [
      r + value,
      g,
      b,
      0,
      0,
      r,
      g + value,
      b,
      0,
      0,
      r,
      g,
      b + value,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ];
  }

  List<double> _multiplyMatrices(List<double> a, List<double> b) {
    final out = List<double>.filled(20, 0.0);
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 5; j++) {
        double sum = 0.0;
        for (int k = 0; k < 4; k++) {
          sum += a[i * 5 + k] * b[k * 5 + j];
        }
        if (j == 4) {
          sum += a[i * 5 + 4]; // add translation from 'a'
        }
        out[i * 5 + j] = sum;
      }
    }
    return out;
  }

  Future<String> _renderFinalImage() async {
    final bytes = await File(widget.mediaUrl).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    final cropRect = _normalizedCropRect;
    final srcRect = Rect.fromLTRB(
      cropRect.left * image.width,
      cropRect.top * image.height,
      cropRect.right * image.width,
      cropRect.bottom * image.height,
    );

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Apply composed color filters using matrix multiplication
    List<double> combined = List<double>.from(_filters[_filterIndex].rawMatrix);
    if (_brightness != 0.0) {
      combined = _multiplyMatrices(_brightnessMatrix(_brightness), combined);
    }
    if (_contrast != 1.0) {
      combined = _multiplyMatrices(_contrastMatrix(_contrast), combined);
    }
    if (_saturation != 1.0) {
      combined = _multiplyMatrices(_saturationMatrix(_saturation), combined);
    }

    final paint = Paint()..colorFilter = ColorFilter.matrix(combined);

    final destRect = Rect.fromLTWH(0, 0, srcRect.width, srcRect.height);
    canvas.drawImageRect(image, srcRect, destRect, paint);

    final picture = recorder.endRecording();
    final filteredImage = await picture.toImage(
      srcRect.width.round(),
      srcRect.height.round(),
    );
    final byteData = await filteredImage.toByteData(
      format: ui.ImageByteFormat.png,
    );

    final tempDir = await getTemporaryDirectory();
    final tempFile = File(
      '${tempDir.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await tempFile.writeAsBytes(byteData!.buffer.asUint8List());

    return tempFile.path;
  }

  Future<void> _onNext() async {
    if (widget.isVideo) {
      final baseUri = widget.mediaUrl.startsWith('http')
          ? Uri.parse(widget.mediaUrl)
          : Uri.file(widget.mediaUrl);
      final uri = baseUri.replace(
        queryParameters: {
          'filterIndex': _filterIndex.toString(),
          'brightness': _brightness.toString(),
          'contrast': _contrast.toString(),
          'saturation': _saturation.toString(),
          if (_thumbnailPath != null && !_thumbnailPath!.startsWith('http'))
            'thumbnailPath': _thumbnailPath!,
        },
      );
      Navigator.of(context).pop(uri.toString());
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final finalPath = await _renderFinalImage();
      if (mounted) {
        Navigator.of(context).pop(finalPath);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        ToastHelper.showToast(
          context,
          "failed to process image: $e",
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.surfaceColor,
      appBar: AppBar(
        backgroundColor: context.surfaceColor,
        foregroundColor: context.textPrimaryColor,
        title: Text(
          'Edit',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: context.textPrimaryColor,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isProcessing ? null : _onNext,
            child: const Text(
              AppStrings.next,
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Center(
                  child: _imageAspectRatio == null
                      ? Stack(
                          children: [
                            Positioned.fill(
                              child: ColorFiltered(
                                colorFilter: _filters[_filterIndex].matrix,
                                child: ColorFiltered(
                                  colorFilter: ColorFilter.matrix(
                                    _brightnessMatrix(_brightness),
                                  ),
                                  child: ColorFiltered(
                                    colorFilter: ColorFilter.matrix(
                                      _contrastMatrix(_contrast),
                                    ),
                                    child: ColorFiltered(
                                      colorFilter: ColorFilter.matrix(
                                        _saturationMatrix(_saturation),
                                      ),
                                      child: _MediaPreview(
                                        url: widget.mediaUrl,
                                        isVideo: widget.isVideo,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (_editorMode == 2)
                              Positioned.fill(
                                child: _CropBox(
                                  aspect: _aspect,
                                  imageAspect: 1.0,
                                  onCropChanged: (rect) {
                                    _normalizedCropRect = rect;
                                  },
                                ),
                              ),
                          ],
                        )
                      : AspectRatio(
                          aspectRatio: _imageAspectRatio!,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: ColorFiltered(
                                  colorFilter: _filters[_filterIndex].matrix,
                                  child: ColorFiltered(
                                    colorFilter: ColorFilter.matrix(
                                      _brightnessMatrix(_brightness),
                                    ),
                                    child: ColorFiltered(
                                      colorFilter: ColorFilter.matrix(
                                        _contrastMatrix(_contrast),
                                      ),
                                      child: ColorFiltered(
                                        colorFilter: ColorFilter.matrix(
                                          _saturationMatrix(_saturation),
                                        ),
                                        child: _MediaPreview(
                                          url: widget.mediaUrl,
                                          isVideo: widget.isVideo,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              if (_editorMode == 2)
                                Positioned.fill(
                                  child: _CropBox(
                                    aspect: _aspect,
                                    imageAspect: _imageAspectRatio!,
                                    onCropChanged: (rect) {
                                      _normalizedCropRect = rect;
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),
                ),
              ),
              _buildModeBar(),
              _buildPanel(),
            ],
          ),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModeBar() {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        border: Border(
          top: BorderSide(color: context.borderColor, width: 0.5),
          bottom: BorderSide(color: context.borderColor, width: 0.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _ModeButton(
            icon: Icons.tune,
            label: 'Filters',
            selected: _editorMode == 0,
            onTap: () => setState(() {
              _editorMode = 0;
              _selectedAdjustment = null;
            }),
          ),
          _ModeButton(
            icon: Icons.photo_filter,
            label: 'Edit',
            selected: _editorMode == 1,
            onTap: () => setState(() => _editorMode = 1),
          ),
          if (!widget.isVideo)
            _ModeButton(
              icon: Icons.crop,
              label: 'Crop',
              selected: _editorMode == 2,
              onTap: () => setState(() {
                _editorMode = 2;
                _selectedAdjustment = null;
              }),
            ),
        ],
      ),
    );
  }

  Widget _buildPanel() {
    switch (_editorMode) {
      case 0:
        return _buildFilterStrip();
      case 1:
        return _buildEditPanel();
      case 2:
        return _buildCropPanel();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildEditPanel() {
    if (_selectedAdjustment != null) {
      double min = -0.5;
      double max = 0.5;
      if (_selectedAdjustment == 'Contrast') {
        min = 0.5;
        max = 1.5;
      } else if (_selectedAdjustment == 'Saturation') {
        min = 0.0;
        max = 2.0;
      }

      return Container(
        height: 104,
        color: context.surfaceColor,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedAdjustment!,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: context.textPrimaryColor,
                    fontSize: 14,
                  ),
                ),
                Text(
                  _tempVal.toStringAsFixed(2),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.close, color: context.textPrimaryColor),
                  onPressed: () {
                    setState(() {
                      // Cancel: revert dynamic edit preview back to original saved value
                      if (_selectedAdjustment == 'Brightness') {
                        _brightness = _brightness;
                      } else if (_selectedAdjustment == 'Contrast') {
                        _contrast = _contrast;
                      } else if (_selectedAdjustment == 'Saturation') {
                        _saturation = _saturation;
                      }
                      _selectedAdjustment = null;
                    });
                  },
                ),
                Expanded(
                  child: Slider(
                    value: _tempVal,
                    min: min,
                    max: max,
                    activeColor: AppColors.primary,
                    inactiveColor: context.borderColor,
                    onChanged: (val) {
                      setState(() {
                        _tempVal = val;
                        if (_selectedAdjustment == 'Brightness') {
                          _brightness = val;
                        } else if (_selectedAdjustment == 'Contrast') {
                          _contrast = val;
                        } else if (_selectedAdjustment == 'Saturation') {
                          _saturation = val;
                        }
                      });
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.check, color: AppColors.primary),
                  onPressed: () {
                    setState(() {
                      if (_selectedAdjustment == 'Brightness') {
                        _brightness = _tempVal;
                      } else if (_selectedAdjustment == 'Contrast') {
                        _contrast = _tempVal;
                      } else if (_selectedAdjustment == 'Saturation') {
                        _saturation = _tempVal;
                      }
                      _selectedAdjustment = null;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      height: 104,
      color: context.surfaceColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _editItem(
            label: 'Brightness',
            icon: Icons.brightness_6_outlined,
            onTap: () {
              setState(() {
                _selectedAdjustment = 'Brightness';
                _tempVal = _brightness;
              });
            },
            isActive: _brightness != 0.0,
          ),
          _editItem(
            label: 'Contrast',
            icon: Icons.contrast_outlined,
            onTap: () {
              setState(() {
                _selectedAdjustment = 'Contrast';
                _tempVal = _contrast;
              });
            },
            isActive: _contrast != 1.0,
          ),
          _editItem(
            label: 'Saturation',
            icon: Icons.opacity,
            onTap: () {
              setState(() {
                _selectedAdjustment = 'Saturation';
                _tempVal = _saturation;
              });
            },
            isActive: _saturation != 1.0,
          ),
        ],
      ),
    );
  }

  Widget _editItem({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required bool isActive,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 80,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive ? AppColors.primary : context.textPrimaryColor,
              size: 24,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive ? AppColors.primary : context.textPrimaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterStrip() {
    return Container(
      height: 104,
      color: context.surfaceColor,
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
                          color: _filterIndex == index
                              ? AppColors.primary
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: ColorFiltered(
                          colorFilter: filter.matrix,
                          child: MediaImage(
                            path: widget.isVideo
                                ? (_thumbnailPath ??
                                      widget.thumbnailUrl ??
                                      'https://picsum.photos/seed/vdefault/400/600')
                                : widget.mediaUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => Container(
                              color: Colors.black26,
                              child: const Icon(
                                Icons.broken_image_outlined,
                                color: Colors.white38,
                              ),
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
                      color: _filterIndex == index
                          ? context.textPrimaryColor
                          : context.textSecondaryColor,
                      fontSize: 11,
                      fontWeight: _filterIndex == index
                          ? FontWeight.w600
                          : FontWeight.w400,
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
      color: context.surfaceColor,
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
                backgroundColor: context.backgroundColor,
                labelStyle: TextStyle(
                  color: _aspect == aspect
                      ? Colors.white
                      : context.textPrimaryColor,
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
      final path = widget.url;
      _controller =
          LocalPostStore.isLocalPath(path)
                ? video.VideoPlayerController.file(File(path))
                : video.VideoPlayerController.networkUrl(Uri.parse(path))
            ..initialize()
                .then((_) {
                  if (!mounted) return;
                  _controller?.setLooping(true);
                  _controller?.setVolume(0);
                  _controller?.play();
                  setState(() {});
                })
                .catchError((_) {
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
        child: const Icon(
          Icons.broken_image_outlined,
          color: Colors.white38,
          size: 48,
        ),
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
          Icon(
            icon,
            color: selected ? context.textPrimaryColor : context.textSecondaryColor,
            size: 22,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: selected ? context.textPrimaryColor : context.textSecondaryColor,
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
  const _CropBox({
    required this.aspect,
    required this.imageAspect,
    required this.onCropChanged,
  });

  final double? aspect;
  final double imageAspect;
  final ValueChanged<Rect> onCropChanged;

  @override
  State<_CropBox> createState() => _CropBoxState();
}

class _CropBoxState extends State<_CropBox> {
  Rect _rect = const Rect.fromLTRB(0.1, 0.1, 0.9, 0.9);
  int? _dragHandle;

  static const double _minSize = 0.2;
  static const double _handleRadius = 14;

  @override
  void initState() {
    super.initState();
    if (widget.aspect != null) _applyAspect();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onCropChanged(_rect);
    });
  }

  @override
  void didUpdateWidget(_CropBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.aspect != widget.aspect ||
        oldWidget.imageAspect != widget.imageAspect) {
      _applyAspect();
      widget.onCropChanged(_rect);
    }
  }

  void _applyAspect() {
    final a = widget.aspect;
    if (a == null) return;
    final imageAspect = widget.imageAspect;
    var w = _rect.width;
    var h = w * imageAspect / a;
    if (h > 1) {
      h = 1;
      w = h * a / imageAspect;
    }
    if (w > 1) {
      w = 1;
      h = w * imageAspect / a;
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
          var left = _rect.left + dx;
          var top = _rect.top + dy;
          if (widget.aspect != null) {
            final w = _rect.right - left;
            final h = w * widget.imageAspect / widget.aspect!;
            top = _rect.bottom - h;
          }
          _rect = _clamp(Rect.fromLTRB(left, top, _rect.right, _rect.bottom));
        case 1:
          var right = _rect.right + dx;
          var top = _rect.top + dy;
          if (widget.aspect != null) {
            final w = right - _rect.left;
            final h = w * widget.imageAspect / widget.aspect!;
            top = _rect.bottom - h;
          }
          _rect = _clamp(Rect.fromLTRB(_rect.left, top, right, _rect.bottom));
        case 2:
          var right = _rect.right + dx;
          var bottom = _rect.bottom + dy;
          if (widget.aspect != null) {
            final w = right - _rect.left;
            final h = w * widget.imageAspect / widget.aspect!;
            bottom = _rect.top + h;
          }
          _rect = _clamp(Rect.fromLTRB(_rect.left, _rect.top, right, bottom));
        case 3:
          var left = _rect.left + dx;
          var bottom = _rect.bottom + dy;
          if (widget.aspect != null) {
            final w = _rect.right - left;
            final h = w * widget.imageAspect / widget.aspect!;
            bottom = _rect.top + h;
          }
          _rect = _clamp(Rect.fromLTRB(left, _rect.top, _rect.right, bottom));
        case 4:
          final r = _rect.shift(Offset(dx, dy));
          if (r.left >= 0 && r.top >= 0 && r.right <= 1 && r.bottom <= 1) {
            _rect = r;
          }
      }
    });
    widget.onCropChanged(_rect);
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
      canvas.drawLine(
        Offset(x, cropRect.top),
        Offset(x, cropRect.bottom),
        grid,
      );
      canvas.drawLine(
        Offset(cropRect.left, y),
        Offset(cropRect.right, y),
        grid,
      );
    }

    final border = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
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
        Paint()
          ..color = Colors.black.withValues(alpha: 0.15)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(_CropPainter oldDelegate) =>
      oldDelegate.cropRect != cropRect ||
      oldDelegate.handleRadius != handleRadius;
}

final _filters = AppFilters.presets;
