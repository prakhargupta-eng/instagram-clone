import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:video_player/video_player.dart' as video;
import 'package:instagram_clone/src/compontes/ToastHelper.dart';

import '../../app.dart';
import '../../constants.dart';
import '../../data/mock_data.dart';
import '../../models/post.dart';
import '../../models/user.dart';
import '../../services/feed_service.dart';
import '../../services/video_cache_service.dart';
import '../../widgets/avatar.dart';
import '../../widgets/shader_filter_widget.dart';
import '../home/comments_sheet.dart';
import '../../widgets/ui_skeletons.dart';

class ReelsScreen extends StatefulWidget {
  const ReelsScreen({
    super.key,
    required this.feedService,
    required this.currentUser,
    this.initialIndex = 0,
    this.visible = true,
  });

  final FeedService feedService;
  final AppUser currentUser;
  final int initialIndex;
  final bool visible;

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  late final PageController _controller = PageController(
    initialPage: widget.initialIndex,
  );
  late int _currentPage = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.feedService,
      builder: (context, _) {
        final rawReels = widget.feedService.posts.where((p) => p.isVideo).toList();
        final isLoading = widget.feedService.isLoading;
        if (isLoading && rawReels.isEmpty) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Skeletonizer(
              enabled: true,
              enableSwitchAnimation: true,
              child: ReelSkeleton(),
            ),
          );
        }

        final reels = rawReels;

        final canPop = Navigator.canPop(context);
        return Scaffold(
          backgroundColor: Colors.black,
          body: Skeletonizer(
            enabled: isLoading,
            enableSwitchAnimation: true,
            child: Stack(
              children: [
                reels.isEmpty
                    ? const Center(
                        child: Text(
                          'No reels yet',
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                    : PageView.builder(
                      controller: _controller,
                      scrollDirection: Axis.vertical,
                      itemCount: null,
                      onPageChanged: (index) =>
                          setState(() => _currentPage = index),
                      itemBuilder: (context, index) {
                        final reelIndex = index % reels.length;
                        final post = reels[reelIndex];
                        return ReelItem(
                          key: ValueKey('${post.id}-$index'),
                          post: post,
                          currentUser: widget.currentUser,
                          feedService: widget.feedService,
                          active: index == _currentPage && widget.visible,
                        );
                      },
                    ),
              if (canPop)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 12,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.4),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 24,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
  }
}

class ReelItem extends StatefulWidget {
  const ReelItem({
    super.key,
    required this.post,
    required this.currentUser,
    required this.feedService,
    required this.active,
  });

  final Post post;
  final AppUser currentUser;
  final FeedService feedService;
  final bool active;

  @override
  State<ReelItem> createState() => _ReelItemState();
}

class _ReelItemState extends State<ReelItem>
    with RouteAware, TickerProviderStateMixin {
  video.VideoPlayerController? _videoController;
  bool _initialized = false;
  bool _playbackFailed = false;
  String? _videoInitId;

  late final AnimationController _rotationController;
  late final AnimationController _heartAnimationController;
  double _progress = 0.0;
  bool _showHeart = false;

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _heartAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _initVideo();
  }

  void _initVideo() async {
    final path = widget.post.videoUrl;
    if (path.isEmpty) return;

    final String currentInitId = widget.post.id;
    _videoInitId = currentInitId;

    try {
      final file = await VideoCacheService.instance.getFile(path);
      if (_videoInitId != currentInitId || !mounted) return;

      final controller = video.VideoPlayerController.file(file);
      _videoController = controller;

      controller.addListener(_videoListener);

      await controller.initialize();
      if (_videoInitId != currentInitId || !mounted) {
        controller.removeListener(_videoListener);
        controller.dispose();
        if (_videoController == controller) {
          _videoController = null;
        }
        return;
      }

      controller.setLooping(true);
      setState(() => _initialized = true);
      if (widget.active) _play();
    } catch (error) {
      debugPrint('ReelItem video init error: $error');
      if (_videoInitId != currentInitId || !mounted) return;
      setState(() => _playbackFailed = true);
    }
  }

  void _videoListener() {
    if (!mounted || _videoController == null) return;
    if (_videoController!.value.isPlaying) {
      if (!_rotationController.isAnimating) {
        _rotationController.repeat();
      }
    } else {
      if (_rotationController.isAnimating) {
        _rotationController.stop();
      }
    }
    setState(() {
      _progress = _videoController!.value.duration.inMilliseconds > 0
          ? _videoController!.value.position.inMilliseconds /
                _videoController!.value.duration.inMilliseconds
          : 0.0;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didUpdateWidget(ReelItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.post.videoUrl != oldWidget.post.videoUrl) {
      _videoInitId = null;
      _initialized = false;
      _playbackFailed = false;
      if (_videoController != null) {
        _videoController!.removeListener(_videoListener);
        _videoController!.dispose();
        _videoController = null;
      }
      _initVideo();
    } else {
      if (widget.active && !oldWidget.active) {
        _play();
      } else if (!widget.active && oldWidget.active) {
        _pause();
      }
    }
  }

  @override
  void didPushNext() {
    if (widget.active) {
      _pause();
    }
  }

  @override
  void didPopNext() {
    if (widget.active) {
      _play();
    }
  }

  @override
  void dispose() {
    _videoInitId = null;
    routeObserver.unsubscribe(this);
    if (_videoController != null) {
      _videoController!.removeListener(_videoListener);
      _videoController!.dispose();
    }
    _rotationController.dispose();
    _heartAnimationController.dispose();
    super.dispose();
  }

  void _play() {
    if (_initialized && !_playbackFailed && _videoController != null) {
      _videoController!.play();
      _rotationController.repeat();
    }
  }

  void _pause() {
    if (_initialized && _videoController != null) {
      _videoController!.pause();
      _rotationController.stop();
    }
  }

  void _togglePlay() {
    if (!_initialized || _playbackFailed || _videoController == null) return;
    if (_videoController!.value.isPlaying) {
      _videoController!.pause();
      _rotationController.stop();
    } else {
      _videoController!.play();
      _rotationController.repeat();
    }
  }

  void _onDoubleTap() {
    final post = widget.feedService.getPost(widget.post.id);
    if (post == null) return;
    if (!post.isLikedBy(widget.currentUser.id)) {
      widget.feedService.toggleLike(widget.post.id, widget.currentUser.id);
    }
    setState(() {
      _showHeart = true;
    });
    _heartAnimationController.forward(from: 0.0).then((_) {
      if (mounted) {
        setState(() {
          _showHeart = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildVideo(),

        _buildGradientOverlay(),
        Positioned.fill(
          child: GestureDetector(
            onTap: _togglePlay,
            onDoubleTap: _onDoubleTap,
            behavior: HitTestBehavior.opaque,
          ),
        ),
        _buildActions(),
        _buildInfo(),
        _buildPlayPauseCenter(),
        _buildHeartOverlay(),
        _buildProgressBar(),
      ],
    );
  }

  Widget _buildVideo() {
    if (_playbackFailed) {
      return Container(
        color: const Color(0xFF1A1A1A),
        alignment: Alignment.center,
        child: const Icon(
          Icons.play_circle_outline,
          color: Colors.white54,
          size: 56,
        ),
      );
    }
    return SizedBox.expand(
      child: _initialized && _videoController != null
          ? ShaderFilterWidget(
              enabled: widget.post.filterIndex == 8,
              child: ColorFiltered(
                colorFilter: AppFilters.getCombinedFilter(
                  widget.post.filterIndex,
                  widget.post.brightness,
                  widget.post.contrast,
                  widget.post.saturation,
                ),
                child: video.VideoPlayer(_videoController!),
              ),
            )
          : Container(
              color: const Color(0xFF1A1A1A),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white70),
              ),
            ),
    );
  }

  Widget _buildGradientOverlay() {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          stops: [0, 0.4, 1],
          colors: [Colors.black87, Colors.transparent, Colors.transparent],
        ),
      ),
    );
  }

  Widget _buildActions() {
    return AnimatedBuilder(
      animation: widget.feedService,
      builder: (context, _) {
        final post = widget.feedService.getPost(widget.post.id);
        if (post == null) return const SizedBox.shrink();
        final isLiked = post.isLikedBy(widget.currentUser.id);
        return Positioned(
          right: 8,
          bottom: 16,
          child: Column(
            children: [
              _ActionButton(
                icon: isLiked ? Icons.favorite : Icons.favorite_border,
                color: isLiked ? const Color(0xFFED4956) : Colors.white,
                label: '${post.likes}',
                onTap: () => widget.feedService.toggleLike(
                  widget.post.id,
                  widget.currentUser.id,
                ),
              ),
              const SizedBox(height: 16),
              _ActionButton(
                assetPath: 'lib/src/asserts/comments.png',
                color: Colors.white,
                label: '${post.comments.length}',
                onTap: () => showCommentsSheet(
                  context,
                  feedService: widget.feedService,
                  post: post,
                  currentUser: widget.currentUser,
                  isDark: true,
                ),
              ),
              const SizedBox(height: 16),
              _ActionButton(
                assetPath: 'lib/src/asserts/forword.png',
                color: Colors.white,
                label: '',
                onTap: () {
                  ToastHelper.showToast(context, "Share menu coming soon!");
                },
              ),
              const SizedBox(height: 16),
              _ActionButton(
                icon: Icons.more_horiz,
                color: Colors.white,
                label: '',
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: const Color(0xFF1E1E1E),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    builder: (context) => Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(
                              Icons.report,
                              color: Colors.red,
                            ),
                            title: const Text(
                              'Report',
                              style: TextStyle(color: Colors.red),
                            ),
                            onTap: () => Navigator.pop(context),
                          ),
                          ListTile(
                            leading: const Icon(
                              Icons.link,
                              color: Colors.white,
                            ),
                            title: const Text(
                              'Copy Link',
                              style: TextStyle(color: Colors.white),
                            ),
                            onTap: () => Navigator.pop(context),
                          ),
                          ListTile(
                            leading: const Icon(
                              Icons.share,
                              color: Colors.white,
                            ),
                            title: const Text(
                              'Share',
                              style: TextStyle(color: Colors.white),
                            ),
                            onTap: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              _buildRotatingMusicDisk(post),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRotatingMusicDisk(Post post) {
    return RotationTransition(
      turns: _rotationController,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const SweepGradient(
            colors: [
              Colors.black,
              Colors.grey,
              Colors.black,
              Colors.grey,
              Colors.black,
            ],
          ),
          border: Border.all(color: Colors.white30, width: 2),
        ),
        child: Center(
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black,
              image: post.author.avatarUrl.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(post.author.avatarUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: post.author.avatarUrl.isEmpty
                ? const Icon(Icons.music_note, color: Colors.white, size: 8)
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildInfo() {
    return AnimatedBuilder(
      animation: widget.feedService,
      builder: (context, _) {
        final isFollowing = widget.feedService.isFollowing(
          widget.currentUser.id,
          widget.post.author.id,
        );
        final isMe = widget.currentUser.id == widget.post.author.id;
        final musicTitle = widget.post.music ?? 'Original Audio';

        return Positioned(
          left: 12,
          right: 200,
          bottom: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Avatar(url: widget.post.author.avatarUrl, radius: 14),
                  const SizedBox(width: 8),
                  Text(
                    widget.post.author.username,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  if (!isMe) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        widget.feedService.toggleFollow(
                          widget.currentUser.id,
                          widget.post.author.id,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isFollowing
                              ? Colors.white24
                              : Colors.transparent,
                          border: Border.all(
                            color: isFollowing
                                ? Colors.transparent
                                : Colors.white,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isFollowing ? 'Following' : 'Follow',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.post.caption,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.music_note, color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Expanded(child: MusicMarquee(text: musicTitle)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlayPauseCenter() {
    if (_videoController == null) return const SizedBox.shrink();
    return ValueListenableBuilder<video.VideoPlayerValue>(
      valueListenable: _videoController!,
      builder: (context, value, _) {
        return AnimatedOpacity(
          opacity: _initialized && !value.isPlaying ? 1 : 0,
          duration: const Duration(milliseconds: 200),
          child: const Icon(
            Icons.play_circle_fill,
            color: Colors.white70,
            size: 64,
          ),
        );
      },
    );
  }

  Widget _buildHeartOverlay() {
    if (!_showHeart) return const SizedBox.shrink();
    return Center(
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.4, end: 1.2)
            .chain(CurveTween(curve: Curves.elasticOut))
            .animate(_heartAnimationController),
        child: FadeTransition(
          opacity: TweenSequence<double>([
            TweenSequenceItem(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              weight: 15,
            ),
            TweenSequenceItem(
              tween: Tween<double>(begin: 1.0, end: 1.0),
              weight: 70,
            ),
            TweenSequenceItem(
              tween: Tween<double>(begin: 1.0, end: 0.0),
              weight: 15,
            ),
          ]).animate(_heartAnimationController),
          child: const Icon(
            Icons.favorite,
            color: Color(0xFFED4956),
            size: 110,
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SizedBox(
        height: 2,
        child: LinearProgressIndicator(
          value: _progress,
          backgroundColor: Colors.white12,
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white70),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    this.icon,
    this.assetPath,
    required this.color,
    required this.label,
    required this.onTap,
  }) : assert(
         icon != null || assetPath != null,
         'Either icon or assetPath must be provided',
       );

  final IconData? icon;
  final String? assetPath;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          if (assetPath != null)
            Image.asset(assetPath!, color: color, width: 28, height: 28)
          else
            Icon(icon, color: color, size: 30),
          if (label.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class MusicMarquee extends StatefulWidget {
  const MusicMarquee({super.key, required this.text});
  final String text;

  @override
  State<MusicMarquee> createState() => _MusicMarqueeState();
}

class _MusicMarqueeState extends State<MusicMarquee>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20,
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return FractionalTranslation(
              translation: Offset(1.0 - _controller.value * 2.0, 0.0),
              child: Text(
                widget.text,
                maxLines: 1,
                overflow: TextOverflow.visible,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
