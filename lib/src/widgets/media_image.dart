
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get_thumbnail_video/video_thumbnail.dart';
import 'package:get_thumbnail_video/index.dart';
import 'package:path_provider/path_provider.dart';

import '../utils/file_helper.dart';
import '../services/local_post_store.dart';

class MediaImage extends StatefulWidget {
  const MediaImage({
    super.key,
    required this.path,
    this.videoUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.color,
    this.colorBlendMode,
    this.errorBuilder,
  });

  final String path;
  final String? videoUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Color? color;
  final BlendMode? colorBlendMode;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;

  @override
  State<MediaImage> createState() => _MediaImageState();
}

class _MediaImageState extends State<MediaImage> {
  static final Map<String, String> _thumbnailCache = {};

  String? _generatedThumbnailPath;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _checkAndGenerateThumbnail();
  }

  @override
  void didUpdateWidget(covariant MediaImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.path != oldWidget.path || widget.videoUrl != oldWidget.videoUrl) {
      _checkAndGenerateThumbnail();
    }
  }

  void _checkAndGenerateThumbnail() {
    if (widget.path.isNotEmpty) {
      return;
    }
    final video = widget.videoUrl;
    if (video == null || video.isEmpty) {
      return;
    }

    if (video.startsWith('http://') || video.startsWith('https://')) {
      // Generating thumbnails for remote videos requires downloading them into memory.
      // Doing this for multiple posts in a grid/feed causes severe ANRs.
      // Remote videos should supply their own thumbnail via post.imageUrl.
      return;
    }

    // Check static cache first
    if (_thumbnailCache.containsKey(video)) {
      setState(() {
        _generatedThumbnailPath = _thumbnailCache[video];
      });
      return;
    }

    setState(() {
      _isGenerating = true;
      _generatedThumbnailPath = null;
    });

    _generateThumbnail(video);
  }

  Future<void> _generateThumbnail(String videoPath) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final xFile = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath: tempDir.path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 400,
        quality: 60,
      );
      if (mounted) {
        _thumbnailCache[videoPath] = xFile.path;
        setState(() {
          _generatedThumbnailPath = xFile.path;
          _isGenerating = false;
        });
      }
    } catch (e) {
      debugPrint('MediaImage error generating thumbnail: $e');
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayPath = widget.path.isNotEmpty
        ? widget.path
        : _generatedThumbnailPath;

    if (displayPath == null || displayPath.isEmpty) {
      if (_isGenerating) {
        return Container(
          width: widget.width,
          height: widget.height,
          color: Colors.black12,
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey),
            ),
          ),
        );
      }
      return widget.errorBuilder != null
          ? widget.errorBuilder!(context, 'No image path or thumbnail available', null)
          : Container(
              width: widget.width,
              height: widget.height,
              color: Colors.black12,
              child: const Icon(Icons.broken_image_outlined, color: Colors.white38),
            );
    }

    if (LocalPostStore.isLocalPath(displayPath)) {
      return Image.file(
        FileHelper.getFile(displayPath),
        fit: widget.fit,
        width: widget.width,
        height: widget.height,
        color: widget.color,
        colorBlendMode: widget.colorBlendMode,
        errorBuilder: widget.errorBuilder,
      );
    }

    return CachedNetworkImage(
      imageUrl: displayPath,
      fit: widget.fit,
      width: widget.width,
      height: widget.height,
      color: widget.color,
      colorBlendMode: widget.colorBlendMode,
      errorWidget: widget.errorBuilder != null
          ? (context, url, error) => widget.errorBuilder!(context, error, null)
          : null,
    );
  }
}
