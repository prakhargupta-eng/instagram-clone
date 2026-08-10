import 'dart:async';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart' as video;
import '../../constants.dart';
import '../../models/story.dart';
import '../../services/local_post_store.dart';
import '../../widgets/avatar.dart';

class StoryViewerScreen extends StatefulWidget {
  const StoryViewerScreen({
    super.key,
    required this.stories,
    required this.initialIndex,
  });

  final List<Story> stories;
  final int initialIndex;

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onStoryComplete() {
    if (_currentIndex < widget.stories.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  void _onTapLeft() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onTapRight() {
    if (_currentIndex < widget.stories.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null && details.primaryVelocity! > 100) {
            Navigator.of(context).pop();
          }
        },
        child: PageView.builder(
          controller: _pageController,
          itemCount: widget.stories.length,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          itemBuilder: (context, index) {
            final story = widget.stories[index];
            return StoryItemView(
              story: story,
              active: index == _currentIndex,
              onComplete: _onStoryComplete,
              onTapLeft: _onTapLeft,
              onTapRight: _onTapRight,
            );
          },
        ),
      ),
    );
  }
}

class StoryItemView extends StatefulWidget {
  const StoryItemView({
    super.key,
    required this.story,
    required this.active,
    required this.onComplete,
    required this.onTapLeft,
    required this.onTapRight,
  });

  final Story story;
  final bool active;
  final VoidCallback onComplete;
  final VoidCallback onTapLeft;
  final VoidCallback onTapRight;

  @override
  State<StoryItemView> createState() => _StoryItemViewState();
}

class _StoryItemViewState extends State<StoryItemView> with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  video.VideoPlayerController? _videoController;
  bool _videoInitialized = false;

  @override
  void initState() {
    super.initState();
    final duration = widget.story.isVideo ? const Duration(seconds: 15) : widget.story.duration;
    _progressController = AnimationController(vsync: this, duration: duration);

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete();
      }
    });

    if (widget.story.isVideo) {
      _initVideo();
    } else {
      if (widget.active) {
        _progressController.forward();
      }
    }
  }

  void _initVideo() {
    final path = widget.story.imageUrl; // videoUrl is mapped to imageUrl in Story model
    _videoController = LocalPostStore.isLocalPath(path)
        ? video.VideoPlayerController.file(File(path))
        : video.VideoPlayerController.networkUrl(Uri.parse(path));

    _videoController!.initialize().then((_) {
      if (!mounted) return;
      setState(() {
        _videoInitialized = true;
      });
      final videoDuration = _videoController!.value.duration;
      _progressController.duration = videoDuration > Duration.zero ? videoDuration : const Duration(seconds: 5);
      if (widget.active) {
        _videoController!.play();
        _progressController.forward();
      }
    }).catchError((_) {
      if (!mounted) return;
      _progressController.duration = const Duration(seconds: 5);
      if (widget.active) {
        _progressController.forward();
      }
    });
  }

  @override
  void didUpdateWidget(StoryItemView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _progressController.forward(from: 0.0);
      _videoController?.seekTo(Duration.zero);
      _videoController?.play();
    } else if (!widget.active && oldWidget.active) {
      _progressController.stop();
      _videoController?.pause();
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  String _timeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Story media background
        Positioned.fill(
          child: widget.story.isVideo
              ? (_videoInitialized && _videoController != null
                  ? AspectRatio(
                      aspectRatio: _videoController!.value.aspectRatio,
                      child: video.VideoPlayer(_videoController!),
                    )
                  : const Center(
                      child: CircularProgressIndicator(color: Colors.white70),
                    ))
              : (LocalPostStore.isLocalPath(widget.story.imageUrl)
                  ? Image.file(
                      File(widget.story.imageUrl),
                      fit: BoxFit.cover,
                    )
                  : CachedNetworkImage(
                      imageUrl: widget.story.imageUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        color: Colors.grey[900],
                        child: const Icon(Icons.broken_image, color: Colors.white54, size: 50),
                      ),
                    )),
        ),

        // Gradient overlay at top & bottom
        Positioned.fill(
          child: Column(
            children: [
              Container(
                height: 120,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black54, Colors.transparent],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                height: 100,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black54],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Controls overlay
        SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Progress indicator bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: AnimatedBuilder(
                  animation: _progressController,
                  builder: (context, _) {
                    return SizedBox(
                      height: 2.5,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: _progressController.value,
                          backgroundColor: Colors.white30,
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // User Info header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Row(
                  children: [
                    Avatar(
                      url: widget.story.user.avatarUrl,
                      radius: 18,
                      showRing: false,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      widget.story.user.username,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _timeAgo(widget.story.createdAt),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 24),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // Interactive tap areas
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: widget.onTapLeft,
                      ),
                    ),
                    Expanded(
                      flex: 7,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: widget.onTapRight,
                      ),
                    ),
                  ],
                ),
              ),

              // Message Reply bar at the bottom
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: Colors.white54, width: 0.8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        alignment: Alignment.centerLeft,
                        child: const Text(
                          'Send message',
                          style: TextStyle(color: Colors.white70, fontSize: 13.5),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.send_outlined, color: Colors.white, size: 22),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
