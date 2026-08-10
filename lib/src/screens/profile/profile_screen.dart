import 'package:flutter/material.dart';

import '../../constants.dart';
import '../../models/post.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/feed_service.dart';
import '../../widgets/avatar.dart';
import 'edit_profile_screen.dart';
import 'changePassword.dart';
import 'compontes/Stat.dart';
import 'compontes/EmptyTab.dart';
import 'compontes/postTitle.dart';
import 'package:instagram_clone/src/compontes/ToastHelper.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.feedService,
    required this.user,
    this.authService,
  });

  final FeedService feedService;
  final AppUser user;
  final AuthService? authService;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(
    length: 3,
    vsync: this,
  );

  FeedService get feedService => widget.feedService;

  AppUser get _displayUser => widget.authService?.currentUser ?? widget.user;
  bool get _isCurrentUser => widget.authService != null;

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listenable = Listenable.merge([feedService, widget.authService]);
    return Scaffold(
      appBar: AppBar(
        title: AnimatedBuilder(
          animation: listenable,
          builder: (context, _) {
            final displayUser = _displayUser;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (displayUser.isPrivate)
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(
                      Icons.lock_outline,
                      size: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                Text(
                  displayUser.username,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            );
          },
        ),
        centerTitle: false,
        actions: [
          if (_isCurrentUser)
            IconButton(
              icon: const Icon(Icons.add_box_outlined),
              onPressed: () {},
            ),
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => _showMenuSheet(context),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: listenable,
        builder: (context, _) {
          final displayUser = _displayUser;
          final liveUser = feedService.userById(displayUser.id) ?? displayUser;
          final posts = feedService.posts
              .where((p) => p.author.id == displayUser.id)
              .toList();
          final isFollowing = widget.authService == null
              ? false
              : feedService.isFollowing(
                  widget.authService!.currentUser!.id,
                  displayUser.id,
                );
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Avatar(url: displayUser.avatarUrl, radius: 40),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Stat(label: '${posts.length}', value: 'Posts'),
                        Stat(
                          label: '${liveUser.followers}',
                          value: 'Followers',
                        ),
                        Stat(
                          label: '${liveUser.following}',
                          value: 'Following',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                displayUser.fullName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              if (displayUser.bio.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  displayUser.bio,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
              if (displayUser.website.isNotEmpty) ...[
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () {
                    ToastHelper.showToast(
                      context,
                      "Opening: ${displayUser.website}",
                    );
                  },
                  child: Text(
                    displayUser.website,
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              if (_isCurrentUser)
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 32,
                        child: OutlinedButton(
                          onPressed: () => _openEditProfile(context),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: AppColors.border,
                              width: 0.8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          child: const Text(
                            'Edit profile',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 32,
                        child: OutlinedButton(
                          onPressed: () {
                            ToastHelper.showToast(
                              context,
                              "Profile link copied",
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: AppColors.border,
                              width: 0.8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          child: const Text(
                            'Share profile',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              else
                SizedBox(
                  height: 32,
                  child: OutlinedButton(
                    onPressed: () => _toggleFollow(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: AppColors.border,
                        width: 0.8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Text(
                      _buttonLabel(isFollowing),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              _buildTabBar(),
              SizedBox(
                height: 420,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPostsTab(posts),
                    _buildReelsTab(posts),
                    _buildTaggedTab(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppColors.textPrimary,
        labelColor: AppColors.textPrimary,
        unselectedLabelColor: AppColors.textSecondary,
        tabs: const [
          Tab(icon: Icon(Icons.grid_on_outlined, size: 22)),
          Tab(icon: Icon(Icons.play_circle_outline, size: 22)),
          Tab(icon: Icon(Icons.person_pin_outlined, size: 22)),
        ],
      ),
    );
  }

  Widget _buildPostsTab(List<Post> posts) {
    if (posts.isEmpty) return const EmptyTab(message: 'No posts yet');
    return GridView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemCount: posts.length,
      itemBuilder: (context, index) =>
          PostTile(feedService: feedService, post: posts[index], posts: posts),
    );
  }

  Widget _buildReelsTab(List<Post> posts) {
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
      itemBuilder: (context, index) =>
          PostTile(feedService: feedService, post: reels[index], posts: reels),
    );
  }

  Widget _buildTaggedTab() {
    return const EmptyTab(message: 'No tagged posts yet');
  }

  String _buttonLabel(bool isFollowing) {
    if (_isCurrentUser) return 'Edit profile';
    return isFollowing ? 'Following' : 'Follow';
  }

  void _openEditProfile(BuildContext context) {
    final auth = widget.authService!;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            EditProfileScreen(authService: auth, user: auth.currentUser!),
      ),
    );
  }

  void _toggleFollow(BuildContext context) {
    final current = widget.authService?.currentUser;
    if (current == null) return;
    feedService.toggleFollow(current.id, _displayUser.id);
    ToastHelper.showToast(context, "Following ${_displayUser.username}");
  }

  void _showMenuSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            if (_isCurrentUser) ..._accountMenuItems(ctx),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  List<Widget> _accountMenuItems(BuildContext ctx) {
    return [
      ListTile(
        leading: const Icon(Icons.password),
        title: const Text(
          AppStrings.changePassword,
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ChangePasswordScreen(authService: widget.authService!),
            ),
          );
        },
      ),
      ListTile(
        leading: const Icon(Icons.logout),
        title: const Text(
          AppStrings.logout,
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        onTap: () {
          Navigator.of(ctx).pop();
          _confirmLogout(ctx);
        },
      ),
      const Divider(height: 1),
      ListTile(
        leading: const Icon(Icons.delete_outline, color: AppColors.error),
        title: const Text(
          AppStrings.deleteAccount,
          style: TextStyle(fontWeight: FontWeight.w500, color: AppColors.error),
        ),
        onTap: () {
          Navigator.of(ctx).pop();
          _confirmDeleteAccount(ctx);
        },
      ),
    ];
  }

  Future<void> _confirmLogout(BuildContext ctx) async {
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.logoutTitle),
        content: const Text(AppStrings.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(AppStrings.logout),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await widget.authService?.logout();
      ToastHelper.showToast(context, "Logged out successfully.");
    }
  }

  Future<void> _confirmDeleteAccount(BuildContext ctx) async {
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.deleteAccountTitle),
        content: const Text(AppStrings.deleteAccountConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              AppStrings.deleteAccount,
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await widget.authService?.deleteAccount();
      ToastHelper.showToast(context, "Account deleted successfully.");
    }
  }
}
