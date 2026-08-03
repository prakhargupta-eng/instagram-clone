import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart' as video;

import '../../models/post.dart';
import '../../models/user.dart';
import '../../services/feed_service.dart';
import '../../widgets/avatar.dart';

class ReelsScreen extends StatefulWidget {
  const ReelsScreen({
    super.key,
    required this.feedService,
    required this.currentUser,
    this.initialIndex = 0,
  });

  final FeedService feedService;
  final AppUser currentUser;
  final int initialIndex;

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  late final PageController _controller =
      PageController(initialPage: widget.initialIndex);
  late int _currentPage = widget.initialIndex;
  late final List<Post> _reels =
      widget.feedService.posts.where((p) => p.isVideo).toList();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _reels.isEmpty
          ? const Center(
              child: Text(
                'No reels yet',
                style: TextStyle(color: Colors.white),
              ),
            )
          : PageView.builder(
              controller: _controller,
              scrollDirection: Axis.vertical,
              itemCount: _reels.length,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemBuilder: (context, index) {
                final post = _reels[index];
                return ReelItem(
                  key: ValueKey(post.id),
                  post: post,
                  currentUser: widget.currentUser,
                  feedService: widget.feedService,
                  active: index == _currentPage,
                );
              },
            ),
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

class _ReelItemState extends State<ReelItem> {
  late final video.VideoPlayerController _videoController;
  bool _initialized = false;
  bool _playbackFailed = false;

  @override
  void initState() {
    super.initState();
    _videoController = video.VideoPlayerController.networkUrl(
      Uri.parse(widget.post.videoUrl),
    );
    _videoController.initialize().then((_) {
      if (!mounted) return;
      setState(() => _initialized = true);
      if (widget.active) _play();
    }).catchError((_) {
      if (!mounted) return;
      setState(() => _playbackFailed = true);
    });
  }

  @override
  void didUpdateWidget(ReelItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _play();
    } else if (!widget.active && oldWidget.active) {
      _pause();
    }
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  void _play() {
    if (_initialized && !_playbackFailed) _videoController.play();
  }

  void _pause() {
    if (_initialized) _videoController.pause();
  }

  void _togglePlay() {
    if (!_initialized || _playbackFailed) return;
    if (_videoController.value.isPlaying) {
      _videoController.pause();
    } else {
      _videoController.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildVideo(),
        Positioned.fill(
          child: GestureDetector(
            onTap: _togglePlay,
            behavior: HitTestBehavior.opaque,
          ),
        ),
        _buildGradientOverlay(),
        _buildActions(),
        _buildInfo(),
        _buildPlayPauseCenter(),
      ],
    );
  }

  Widget _buildVideo() {
    if (_playbackFailed) {
      return Container(
        color: const Color(0xFF1A1A1A),
        alignment: Alignment.center,
        child: const Icon(Icons.play_circle_outline, color: Colors.white54, size: 56),
      );
    }
    return SizedBox.expand(
      child: _initialized
          ? video.VideoPlayer(_videoController)
          : Container(
              color: const Color(0xFF1A1A1A),
              child: const Center(child: CircularProgressIndicator(color: Colors.white70)),
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
    return Positioned(
      right: 8,
      bottom: 80,
      child: Column(
        children: [
          _ActionButton(
            icon: widget.post.isLikedBy(widget.currentUser.id)
                ? Icons.favorite
                : Icons.favorite_border,
            color: widget.post.isLikedBy(widget.currentUser.id) ? const Color(0xFFED4956) : Colors.white,
            label: '${widget.post.likes}',
            onTap: () =>
                widget.feedService.toggleLike(widget.post.id, widget.currentUser.id),
          ),
          const SizedBox(height: 16),
          _ActionButton(
            icon: Icons.chat_bubble_outline,
            color: Colors.white,
            label: '${widget.post.comments.length}',
            onTap: () {},
          ),
          const SizedBox(height: 16),
          _ActionButton(
            icon: Icons.send_outlined,
            color: Colors.white,
            label: '',
            onTap: () {},
          ),
          const SizedBox(height: 16),
          _ActionButton(
            icon: Icons.more_horiz,
            color: Colors.white,
            label: '',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildInfo() {
    return Positioned(
      left: 12,
      right: 60,
      bottom: 90,
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
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Follow',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.post.caption,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayPauseCenter() {
    return ValueListenableBuilder<video.VideoPlayerValue>(
      valueListenable: _videoController,
      builder: (context, value, _) {
        return AnimatedOpacity(
          opacity: _initialized && !value.isPlaying ? 1 : 0,
          duration: const Duration(milliseconds: 200),
          child: const Icon(Icons.play_circle_fill, color: Colors.white70, size: 64),
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          if (label.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ],
      ),
    );
  }
}
