import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:audioplayers/audioplayers.dart';

import '../../adaptive_colors.dart';
import '../../app.dart';
import '../../constants.dart';
import '../../models/post.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/feed_service.dart';
import '../../services/music_service.dart';
import '../../widgets/post_card.dart';
import '../../widgets/story_bar.dart';
import '../create/create_post_screen.dart';
import 'comments_sheet.dart';
import '../chat/chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.authService,
    required this.feedService,
    this.visible = true,
  });

  final AuthService authService;
  final FeedService feedService;
  final bool visible;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RouteAware {
  AppUser get _currentUser => widget.authService.currentUser!;

  late final ScrollController _scrollController;
  final Map<String, GlobalKey> _cardKeys = {};
  int _currentIndex = 0;
  List<Post> _currentFeedList = [];

  bool _isPlaying = false;
  bool _isMuted = false;
  bool _isRouteActive = true;
  String? _selectedFeedTag;

  GlobalKey _getKeyForPost(String postId) {
    return _cardKeys.putIfAbsent(postId, () => GlobalKey());
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _onScroll();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didUpdateWidget(HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.visible && oldWidget.visible) {
      if (_isPlaying) {
        MusicService.instance.pausePostMusic();
        setState(() {
          _isPlaying = false;
        });
      }
    } else if (widget.visible && !oldWidget.visible) {
      _onScroll();
    }
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
    if (widget.visible) {
      _onScroll();
    }
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
    if (!mounted || _currentFeedList.isEmpty) return;
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
        if (_isPlaying) {
          MusicService.instance.pausePostMusic();
          setState(() {
            _isPlaying = false;
          });
        }
      } else {
        final index = _currentFeedList.indexWhere((p) => p.id == closestPostId);
        if (index != -1) {
          if (index != _currentIndex) {
            setState(() {
              _currentIndex = index;
            });
            _playMusicForPost(_currentFeedList[index]);
          } else {
            if (MusicService.instance.player.state != PlayerState.playing &&
                !MusicService.instance.userPaused) {
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
          _isPlaying =
              MusicService.instance.player.state == PlayerState.playing;
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

  Future<void> _stopAndDisposeAudio() async {
    await MusicService.instance.stop();
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    MusicService.instance.setMuted(_isMuted);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        backgroundColor: context.backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 16,
        title: Text(
          AppStrings.appName,
          style: TextStyle(
            fontFamily: 'serif',
            fontStyle: FontStyle.italic,
            fontSize: 28,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
            color: context.textPrimaryColor,
          ),
        ),
        actions: [
          IconButton(
            icon: Image.asset(
              'lib/src/asserts/massageIcon.png',
              width: 27,
              height: 27,
              color: context.textPrimaryColor,
              colorBlendMode: BlendMode.srcIn,
              errorBuilder: (_, _, _) => Icon(
                Icons.send_outlined,
                color: context.textPrimaryColor,
                size: 27,
              ),
            ),
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const ChatScreen()));
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(color: context.borderColor, height: 0.5),
        ),
      ),
      body: AnimatedBuilder(
        animation: widget.feedService,
        builder: (context, _) {
          final followingFeed = widget.feedService.followingFeed(_currentUser);
          if (followingFeed.isNotEmpty) {
            return _buildFeed(followingFeed, 'following');
          } else {
            var publicPosts = widget.feedService.posts.where((p) {
              final author =
                  widget.feedService.userById(p.author.id) ?? p.author;
              return !author.isPrivate;
            }).toList();

            if (_selectedFeedTag != null) {
              publicPosts = publicPosts
                  .where(
                    (p) => p.caption.toLowerCase().contains(
                      _selectedFeedTag!.toLowerCase(),
                    ),
                  )
                  .toList();
            }
            return _buildFeed(publicPosts, 'public', showSuggestions: true);
          }
        },
      ),
    );
  }

  Widget _buildFeed(
    List<Post> feed,
    String keySuffix, {
    bool showSuggestions = false,
  }) {
    _currentFeedList = feed;
    final sessionKey = widget.authService.sessionKey;
    final pending = widget.feedService.pendingUploads;

    final isLoading = widget.feedService.isLoading;

    return RefreshIndicator(
      onRefresh: () => widget.feedService.refreshFeed(),
      child: Skeletonizer(
        enabled: isLoading,
        enableSwitchAnimation: true,
        child: ListView.builder(
          controller: _scrollController,
          key: PageStorageKey(
            'feed_${_currentUser.id}_${sessionKey}_$keySuffix',
          ),
          padding: EdgeInsets.zero,
          itemCount: feed.length + 1 + pending.length,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StoryBar(
                    stories: widget.feedService.storiesFor(_currentUser),
                    currentUser: _currentUser,
                    feedService: widget.feedService,
                    onAddStory: _openCreateStory,
                  ),
                  if (showSuggestions) ...[
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 16,
                        top: 12,
                        bottom: 4,
                      ),
                      child: Text(
                        'Explore Trending Tags',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: context.textPrimaryColor,
                        ),
                      ),
                    ),
                    _buildSuggestedTagsRow(_suggestedTags),
                    const SizedBox(height: 8),
                  ],
                ],
              );
            }

            if (index <= pending.length) {
              final upload = pending[index - 1];
              return _buildPendingUploadItem(upload);
            }

            final post = feed[index - 1 - pending.length];
            return Container(
              key: _getKeyForPost(post.id),
              child: Column(
                children: [
                  Divider(
                    height: 0.5,
                    thickness: 0.5,
                    color: context.borderColor,
                  ),
                  PostCard(
                    post: post,
                    currentUserId: _currentUser.id,
                    author:
                        widget.feedService.userById(post.author.id) ??
                        post.author,
                    isMuted: _isMuted,
                    isActive:
                        _currentIndex == (index - 1 - pending.length) &&
                        widget.visible &&
                        _isRouteActive,
                    onMuteToggle: _toggleMute,
                    onLike: () =>
                        widget.feedService.toggleLike(post.id, _currentUser.id),
                    onComment: () => showCommentsSheet(
                      context,
                      feedService: widget.feedService,
                      post: post,
                      currentUser: _currentUser,
                    ),
                    isBookmarked: widget.feedService.isBookmarked(post.id),
                    onBookmark: () =>
                        widget.feedService.toggleBookmark(post.id),
                    onTapMedia: () {
                      if (post.music != null && post.music!.isNotEmpty) {
                        _toggleMute();
                      }
                    },
                    onDelete: () => widget.feedService.deletePost(post.id),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPendingUploadItem(PendingUpload upload) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        border: Border(
          bottom: BorderSide(color: context.borderColor, width: 0.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // 20x20 Preview Image
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: context.borderColor, width: 0.5),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: CachedNetworkImage(
                    imageUrl: upload.imageUrl,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) {
                      return Container(color: context.borderColor);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Text "Uploading..."
              Expanded(
                child: Text(
                  'Uploading...',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: upload.progress,
              backgroundColor: context.borderColor.withOpacity(0.5),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
              minHeight: 3,
            ),
          ),
        ],
      ),
    );
  }

  void _openCreateStory() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreatePostScreen(
          feedService: widget.feedService,
          currentUser: _currentUser,
          isStory: true,
        ),
      ),
    );
  }

  List<String> get _suggestedTags {
    final frequency = <String, int>{};
    for (final post in widget.feedService.posts) {
      final caption = post.caption;
      final RegExp regExp = RegExp(r'#\w+');
      final matches = regExp.allMatches(caption);
      for (final match in matches) {
        final tag = match.group(0)!;
        frequency[tag] = (frequency[tag] ?? 0) + 1;
      }
    }
    final sortedTags = frequency.keys.toList()
      ..sort((a, b) => frequency[b]!.compareTo(frequency[a]!));
    return sortedTags.take(5).toList();
  }

  Widget _buildSuggestedTagsRow(List<String> topTags) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: topTags.length,
        itemBuilder: (context, index) {
          final tag = topTags[index];
          final isSelected = _selectedFeedTag == tag;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                tag,
                style: TextStyle(
                  color: isSelected ? Colors.white : context.textPrimaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedFeedTag = tag;
                  } else {
                    _selectedFeedTag = null;
                  }
                });
              },
              backgroundColor: context.surfaceColor,
              selectedColor: Colors.blue,
              checkmarkColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(
                  color: isSelected ? Colors.transparent : context.borderColor,
                  width: 0.5,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
