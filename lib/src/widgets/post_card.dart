import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart' as video;

import '../constants.dart';
import '../models/post.dart';
import '../models/user.dart';
import '../services/local_post_store.dart';
import 'avatar.dart';
import 'media_image.dart';

class PostCard extends StatefulWidget {
  const PostCard({
    super.key,
    required this.post,
    required this.currentUserId,
    required this.onLike,
    required this.onComment,
    this.onTapMedia,
    required this.isBookmarked,
    this.onBookmark,
    required this.author,
    this.isMuted = false,
    this.isActive = false,
    this.onMuteToggle,
  });

  final Post post;
  final String currentUserId;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback? onTapMedia;
  final bool isBookmarked;
  final VoidCallback? onBookmark;
  final AppUser author;
  final bool isMuted;
  final bool isActive;
  final VoidCallback? onMuteToggle;

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> with SingleTickerProviderStateMixin {
  late final AnimationController _heartAnimController;
  late final Animation<double> _heartScale;
  bool _showHeartOverlay = false;

  video.VideoPlayerController? _videoController;
  bool _videoInitialized = false;

  @override
  void initState() {
    super.initState();
    _heartAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _heartScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.2)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 0.9)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.9, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 30,
      ),
    ]).animate(_heartAnimController);

    if (widget.post.isVideo) {
      _initVideo();
    }
  }

  void _initVideo() {
    final path = widget.post.videoUrl;
    _videoController = LocalPostStore.isLocalPath(path)
        ? video.VideoPlayerController.file(File(path))
        : video.VideoPlayerController.networkUrl(Uri.parse(path));

    _videoController!.initialize().then((_) {
      if (!mounted) return;
      _videoController!.setLooping(true);
      _videoController!.setVolume(widget.isMuted ? 0.0 : 1.0);
      setState(() {
        _videoInitialized = true;
      });
      if (widget.isActive) {
        _videoController!.play();
      }
    }).catchError((e) {
      debugPrint('PostCard video init error: $e');
    });
  }

  @override
  void didUpdateWidget(PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.post.isVideo) {
      if (_videoController == null) {
        _initVideo();
      } else {
        if (widget.isMuted != oldWidget.isMuted) {
          _videoController!.setVolume(widget.isMuted ? 0.0 : 1.0);
        }
        if (widget.isActive && !oldWidget.isActive) {
          _videoController!.play();
        } else if (!widget.isActive && oldWidget.isActive) {
          _videoController!.pause();
        }
      }
    } else {
      if (_videoController != null) {
        _videoController!.dispose();
        _videoController = null;
        _videoInitialized = false;
      }
    }
  }

  @override
  void dispose() {
    _heartAnimController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  void _triggerDoubleTapLike() {
    if (!widget.post.isLikedBy(widget.currentUserId)) {
      widget.onLike();
    }
    setState(() {
      _showHeartOverlay = true;
    });
    _heartAnimController.forward(from: 0.0).then((_) {
      if (mounted) {
        setState(() {
          _showHeartOverlay = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(context),
        _media(context),
        _actions(context),
        _likesText(context),
        _caption(context),
        _commentsPreview(context),
        _timestamp(context),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
      child: Row(
        children: [
          Avatar(url: widget.author.avatarUrl, radius: 18, showRing: false),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.author.username,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
                if (widget.post.location != null && widget.post.location!.isNotEmpty)
                  Text(
                    widget.post.location!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                if (widget.post.music != null && widget.post.music!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        MusicVisualizer(isPlaying: !widget.isMuted),
                        const SizedBox(width: 4),
                        Text(
                          widget.post.music!.contains('|\$\$\$|')
                              ? widget.post.music!.split('|\$\$\$|')[0]
                              : widget.post.music!,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_horiz, size: 22, color: AppColors.textPrimary),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _media(BuildContext context) {
    final showVolumeIcon = widget.post.isVideo || (widget.post.music != null && widget.post.music!.isNotEmpty);

    return GestureDetector(
      onDoubleTap: _triggerDoubleTapLike,
      onTap: () {
        if (widget.post.isVideo) {
          if (widget.onMuteToggle != null) {
            widget.onMuteToggle!();
          }
        } else {
          if (widget.onTapMedia != null) {
            widget.onTapMedia!();
          }
        }
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: widget.post.isVideo && _videoInitialized && _videoController != null
                ? ClipRect(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      clipBehavior: Clip.hardEdge,
                      child: SizedBox(
                        width: _videoController!.value.size.width,
                        height: _videoController!.value.size.height,
                        child: video.VideoPlayer(_videoController!),
                      ),
                    ),
                  )
                : MediaImage(
                    path: widget.post.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: AppColors.border,
                      child: const Icon(
                        Icons.broken_image_outlined,
                        color: AppColors.textSecondary,
                        size: 40,
                      ),
                    ),
                  ),
          ),
          if (widget.post.isVideo && !_videoInitialized)
            const Positioned.fill(
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          if (showVolumeIcon)
            Positioned(
              bottom: 12,
              right: 12,
              child: GestureDetector(
                onTap: widget.onMuteToggle,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.isMuted ? Icons.volume_off : Icons.volume_up,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          if (_showHeartOverlay)
            ScaleTransition(
              scale: _heartScale,
              child: const Icon(
                Icons.favorite,
                color: Colors.white,
                size: 80,
                shadows: [
                  Shadow(
                    blurRadius: 15,
                    color: Colors.black45,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _actions(BuildContext context) {
    final isLiked = widget.post.isLikedBy(widget.currentUserId);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
      child: Row(
        children: [
          // Like button
          GestureDetector(
            onTap: widget.onLike,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Image.asset(
                'lib/src/asserts/Heart.png',
                width: 26,
                height: 26,
                color: isLiked ? AppColors.error : AppColors.textPrimary,
                colorBlendMode: BlendMode.srcIn,
                errorBuilder: (_, _, _) => Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked ? AppColors.error : AppColors.textPrimary,
                  size: 26,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Comment button
          GestureDetector(
            onTap: widget.onComment,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Image.asset(
                'lib/src/asserts/comments.png',
                width: 24,
                height: 24,
                color: AppColors.textPrimary,
                colorBlendMode: BlendMode.srcIn,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.chat_bubble_outline,
                  color: AppColors.textPrimary,
                  size: 24,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Share / Send button
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sharing feature coming soon!'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Image.asset(
                'lib/src/asserts/forword.png',
                width: 24,
                height: 24,
                color: AppColors.textPrimary,
                colorBlendMode: BlendMode.srcIn,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.send_outlined,
                  color: AppColors.textPrimary,
                  size: 24,
                ),
              ),
            ),
          ),
          const Spacer(),
          // Bookmark button
          GestureDetector(
            onTap: widget.onBookmark,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: widget.isBookmarked
                  ? const Icon(
                      Icons.bookmark,
                      color: AppColors.textPrimary,
                      size: 24,
                    )
                  : Image.asset(
                      'lib/src/asserts/bookmark.png',
                      width: 22,
                      height: 22,
                      color: AppColors.textPrimary,
                      colorBlendMode: BlendMode.srcIn,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.bookmark_border,
                        color: AppColors.textPrimary,
                        size: 24,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _likesText(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 0),
      child: Text(
        '${_formatCount(widget.post.likes)} ${AppStrings.likes}',
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          fontSize: 13.5,
        ),
      ),
    );
  }

  Widget _caption(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 3, 12, 0),
      child: RichText(
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13.5, height: 1.35),
          children: [
            TextSpan(
              text: '${widget.author.username} ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: widget.post.caption),
            const TextSpan(
              text: ' more',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _commentsPreview(BuildContext context) {
    if (widget.post.comments.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      child: GestureDetector(
        onTap: widget.onComment,
        child: Text(
          'View all ${widget.post.comments.length} comments',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      ),
    );
  }

  Widget _timestamp(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      child: Text(
        _relativeTime(widget.post.createdAt),
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 10.5),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) {
      final formatted = (count / 1000).toStringAsFixed(
        count % 1000 == 0 ? 0 : 3,
      );
      return '${formatted.replaceAll(RegExp(r'\.?0+$'), '')},${(count % 1000).toString().padLeft(3, '0')}';
    }
    return count.toString();
  }

  String _relativeTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return DateFormat('MMM d').format(time);
  }
}

class MusicVisualizer extends StatefulWidget {
  const MusicVisualizer({super.key, required this.isPlaying});
  final bool isPlaying;

  @override
  State<MusicVisualizer> createState() => _MusicVisualizerState();
}

class _MusicVisualizerState extends State<MusicVisualizer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    if (widget.isPlaying) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant MusicVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isPlaying) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (index) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 0.8),
          width: 1.8,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.textSecondary,
            borderRadius: BorderRadius.circular(0.5),
          ),
        )),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          height: 10,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _bar(0.3 + 0.7 * (0.5 + 0.5 * math.sin(_controller.value * 2 * math.pi + 0))),
              _bar(0.3 + 0.7 * (0.5 + 0.5 * math.sin(_controller.value * 2 * math.pi + 2))),
              _bar(0.3 + 0.7 * (0.5 + 0.5 * math.sin(_controller.value * 2 * math.pi + 4))),
            ],
          ),
        );
      },
    );
  }

  Widget _bar(double heightPercent) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0.8),
      width: 1.8,
      height: 10 * heightPercent,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(0.5),
      ),
    );
  }
}
