import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../app.dart';
import '../../constants.dart';
import '../../models/post.dart';
import '../../services/feed_service.dart';
import '../../widgets/post_card.dart';
import '../home/comments_sheet.dart';
import '../../services/music_service.dart';

class DetailsScreen extends StatefulWidget {
  const DetailsScreen({
    super.key,
    required this.post,
    this.posts,
    required this.feedService,
  });

  final Post post;
  final List<Post>? posts;
  final FeedService feedService;

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> with RouteAware {
  late final List<Post> _postList;
  late final ScrollController _scrollController;
  final Map<String, GlobalKey> _cardKeys = {};
  int _currentIndex = 0;

  bool _isPlaying = false;
  bool _isMuted = false;
  bool _isRouteActive = true;

  GlobalKey _getKeyForPost(String postId) {
    return _cardKeys.putIfAbsent(postId, () => GlobalKey());
  }

  @override
  void initState() {
    super.initState();
    _postList = List<Post>.from(widget.posts ?? [widget.post]);
    _currentIndex = _postList.indexWhere((p) => p.id == widget.post.id);
    if (_currentIndex == -1) _currentIndex = 0;

    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Jump to the tapped initial post
      final targetKey = _getKeyForPost(widget.post.id);
      final context = targetKey.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(
          context,
          alignment: 0.0,
          duration: Duration.zero,
        );
      }
      // Trigger center detection on first frame
      _onScroll();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didPushNext() {
    setState(() {
      _isRouteActive = false;
    });
    if (_isPlaying) {
      MusicService.instance.pausePostMusic();
      setState(() {
        _isPlaying = false;
      });
    }
  }

  @override
  void didPopNext() {
    setState(() {
      _isRouteActive = true;
    });
    _onScroll();
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _stopAndDisposeAudio();
    super.dispose();
  }

  void _onScroll() {
    if (!mounted) return;
    final screenCenterY = MediaQuery.of(context).size.height / 2;

    String? closestPostId;
    double closestDistance = double.infinity;

    for (final entry in _cardKeys.entries) {
      final key = entry.value;
      final context = key.currentContext;
      if (context == null) continue;

      final box = context.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) continue;

      final position = box.localToGlobal(Offset.zero);
      final itemCenterY = position.dy + box.size.height / 2;

      final distance = (itemCenterY - screenCenterY).abs();
      if (distance < closestDistance) {
        closestDistance = distance;
        closestPostId = entry.key;
      }
    }

    if (closestPostId != null) {
      final maxDistance = MediaQuery.of(context).size.height / 3;
      if (closestDistance > maxDistance) {
        // Paused/stopped if moved too far from viewport center
        if (_isPlaying) {
          MusicService.instance.pausePostMusic();
          setState(() {
            _isPlaying = false;
          });
        }
      } else {
        final index = _postList.indexWhere((p) => p.id == closestPostId);
        if (index != -1) {
          if (index != _currentIndex) {
            setState(() {
              _currentIndex = index;
            });
            _playMusicForPost(_postList[index]);
          } else {
            // Re-play if scrolled back into center and user hasn't explicitly paused
            if (MusicService.instance.player.state != PlayerState.playing && !MusicService.instance.userPaused) {
              MusicService.instance.resumePostMusic();
              setState(() {
                _isPlaying = true;
              });
            }
          }
        }
      }
    }
  }

  void _playMusicForPost(Post post) async {
    if (post.isVideo) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
      await MusicService.instance.stop();
      return;
    }

    try {
      await MusicService.instance.setMuted(_isMuted);
      await MusicService.instance.playPostMusic(
        post.music,
        previewUrl: post.musicPreviewUrl,
      );
      if (mounted) {
        setState(() {
          _isPlaying = MusicService.instance.player.state == PlayerState.playing;
        });
      }
    } catch (e) {
      debugPrint('Error playing song: $e');
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
    }
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    MusicService.instance.setMuted(_isMuted);
  }

  Future<void> _stopAndDisposeAudio() async {
    await MusicService.instance.stop();
  }

  @override
  Widget build(BuildContext context) {
    final authService = AppScope.of(context).authService;
    final currentUser = authService.currentUser!;
    final activePost = _postList.isNotEmpty ? _postList[_currentIndex] : widget.post;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: const Text(
          'Posts',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      body: AnimatedBuilder(
        animation: widget.feedService,
        builder: (context, _) {
          return ListView.builder(
            controller: _scrollController,
            itemCount: _postList.length,
            itemBuilder: (context, index) {
              final post = widget.feedService.posts.firstWhere((p) => p.id == _postList[index].id, orElse: () => _postList[index]);
              final author = widget.feedService.userById(post.author.id) ?? post.author;

              return Container(
                key: _getKeyForPost(post.id),
                child: Column(
                  children: [
                    PostCard(
                      post: post,
                      currentUserId: currentUser.id,
                      author: author,
                      isMuted: _isMuted,
                      isActive: _currentIndex == index && _isRouteActive,
                      onMuteToggle: _toggleMute,
                      onLike: () => widget.feedService.toggleLike(post.id, currentUser.id),
                      onComment: () => showCommentsSheet(
                        context,
                        feedService: widget.feedService,
                        post: post,
                        currentUser: currentUser,
                      ),
                      isBookmarked: widget.feedService.isBookmarked(post.id),
                      onBookmark: () => widget.feedService.toggleBookmark(post.id),
                      onTapMedia: () {
                        if (post.music != null && post.music!.isNotEmpty) {
                          _toggleMute();
                        }
                      },
                      onDelete: () {
                        widget.feedService.deletePost(post.id);
                        if (_postList.length <= 1) {
                          Navigator.of(context).pop();
                        } else {
                          setState(() {
                            _postList.removeAt(_currentIndex);
                            if (_currentIndex >= _postList.length) {
                              _currentIndex = _postList.length - 1;
                            }
                            _playMusicForPost(_postList[_currentIndex]);
                          });
                        }
                      },
                    ),
                    const Divider(height: 1, thickness: 0.5, color: AppColors.border),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}