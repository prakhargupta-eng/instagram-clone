import 'package:flutter/material.dart';

import '../../constants.dart';
import '../../models/post.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/feed_service.dart';
import '../../widgets/post_card.dart';
import '../../widgets/story_bar.dart';
import '../create/create_post_screen.dart';
import '../reels/reels_screen.dart';
import 'comments_sheet.dart';
import '../chat/chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.authService, required this.feedService});

  final AuthService authService;
  final FeedService feedService;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  AppUser get _currentUser => widget.authService.currentUser!;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 16,
        title: Text(
          AppStrings.appName,
          style: const TextStyle(
            fontFamily: 'serif',
            fontStyle: FontStyle.italic,
            fontSize: 28,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: Image.asset(
              'lib/src/asserts/massageIcon.png',
              width: 27,
              height: 27,
              color: AppColors.textPrimary,
              colorBlendMode: BlendMode.srcIn,
              errorBuilder: (_, _, _) => const Icon(Icons.send_outlined, color: AppColors.textPrimary, size: 27),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ChatScreen()),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(color: AppColors.border, height: 0.5),
        ),
      ),
      body: AnimatedBuilder(
        animation: widget.feedService,
        builder: (context, _) {
          return _buildFeed(widget.feedService.forYouFeed(_currentUser), 'foryou');
        },
      ),
    );
  }

  Widget _buildFeed(List<Post> feed, String keySuffix) {
    final sessionKey = widget.authService.sessionKey;
    return ListView.builder(
      key: PageStorageKey('feed_${_currentUser.id}_${sessionKey}_$keySuffix'),
      padding: EdgeInsets.zero,
      itemCount: feed.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return StoryBar(
            stories: widget.feedService.storiesFor(_currentUser),
            currentUser: _currentUser,
            onAddStory: _openCreatePost,
          );
        }
        final post = feed[index - 1];
        return Column(
          children: [
            const Divider(height: 0.5, thickness: 0.5, color: AppColors.border),
            PostCard(
              post: post,
              currentUserId: _currentUser.id,
              author: widget.feedService.userById(post.author.id) ?? post.author,
              onLike: () => widget.feedService.toggleLike(post.id, _currentUser.id),
              onComment: () => showCommentsSheet(
                context,
                feedService: widget.feedService,
                post: post,
                currentUser: _currentUser,
              ),
              isBookmarked: widget.feedService.isBookmarked(post.id),
              onBookmark: () => widget.feedService.toggleBookmark(post.id),
              onTapMedia: post.isVideo
                  ? () => _openReels(post.id)
                  : null,
            ),
          ],
        );
      },
    );
  }

  void _openReels(String postId) {
    final reels = widget.feedService.posts.where((p) => p.isVideo).toList();
    final index = reels.indexWhere((p) => p.id == postId);
    if (index < 0) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ReelsScreen(
          feedService: widget.feedService,
          currentUser: _currentUser,
          initialIndex: index,
        ),
      ),
    );
  }

  void _openCreatePost() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreatePostScreen(
          feedService: widget.feedService,
          currentUser: _currentUser,
        ),
      ),
    );
  }


}


