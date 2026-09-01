import 'package:flutter/material.dart';
import '../../../models/post.dart';
import '../../../models/user.dart';
import '../../../services/feed_service.dart';
import '../../../adaptive_colors.dart';
import 'EmptyTab.dart';
import 'postTitle.dart';

class ProfileTabsWidget extends StatelessWidget {
  const ProfileTabsWidget({
    super.key,
    required this.tabController,
    required this.posts,
    required this.feedService,
    required this.displayUser,
  });

  final TabController tabController;
  final List<Post> posts;
  final FeedService feedService;
  final AppUser displayUser;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildTabBar(context),
        SizedBox(
          height: 420,
          child: TabBarView(
            controller: tabController,
            children: [
              _buildPostsTab(),
              _buildReelsTab(),
              _buildTaggedTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: context.borderColor, width: 0.5),
        ),
      ),
      child: TabBar(
        controller: tabController,
        indicatorColor: context.textPrimaryColor,
        labelColor: context.textPrimaryColor,
        unselectedLabelColor: context.textSecondaryColor,
        tabs: const [
          Tab(icon: Icon(Icons.grid_on_outlined, size: 22)),
          Tab(icon: Icon(Icons.play_circle_outline, size: 22)),
          Tab(icon: Icon(Icons.person_pin_outlined, size: 22)),
        ],
      ),
    );
  }

  Widget _buildPostsTab() {
    if (posts.isEmpty) return const EmptyTab(message: 'No posts yet');
    return GridView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemCount: posts.length,
      itemBuilder: (context, index) => PostTile(
        feedService: feedService,
        post: posts[index],
        posts: posts,
        heroTag: 'posts_${posts[index].id}',
      ),
    );
  }

  Widget _buildReelsTab() {
    final reels = posts.where((p) => p.isVideo).toList();
    if (reels.isEmpty) return const EmptyTab(message: 'No reels yet');
    return GridView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemCount: reels.length,
      itemBuilder: (context, index) => PostTile(
        feedService: feedService,
        post: reels[index],
        posts: reels,
        heroTag: 'reels_${reels[index].id}',
      ),
    );
  }

  Widget _buildTaggedTab() {
    final taggedPosts = feedService.posts
        .where((p) => p.taggedUsers.any((u) => u.id == displayUser.id))
        .toList();
    if (taggedPosts.isEmpty) {
      return const EmptyTab(message: 'Photos and videos of you');
    }
    return GridView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemCount: taggedPosts.length,
      itemBuilder: (context, index) => PostTile(
        feedService: feedService,
        post: taggedPosts[index],
        posts: taggedPosts,
        heroTag: 'tagged_${taggedPosts[index].id}',
      ),
    );
  }
}
