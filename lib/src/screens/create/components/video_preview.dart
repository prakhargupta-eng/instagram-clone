import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart' as video;
import '../../../constants.dart';
import '../../../services/local_post_store.dart';

class CreateVideoPreview extends StatefulWidget {
  const CreateVideoPreview({super.key, required this.url});

  final String url;

  @override
  State<CreateVideoPreview> createState() => _CreateVideoPreviewState();
}

class _CreateVideoPreviewState extends State<CreateVideoPreview> {
  video.VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    final path = widget.url;
    _controller = LocalPostStore.isLocalPath(path)
        ? video.VideoPlayerController.file(File(path))
        : video.VideoPlayerController.networkUrl(Uri.parse(path))
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

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return Container(
        color: AppColors.background,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(color: AppColors.primary),
      );
    }
    return video.VideoPlayer(controller);
  }
}
