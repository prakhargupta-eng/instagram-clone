import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../adaptive_colors.dart';
import '../../app.dart';

import '../../constants.dart';
import '../../models/post.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/feed_service.dart';
import '../../services/api_service.dart';
import '../../widgets/avatar.dart';
import '../../widgets/ui_skeletons.dart';
import 'edit_profile_screen.dart';
import 'changePassword.dart';
import 'bookmarks/bookmarks_screen.dart';
import 'compontes/Stat.dart';
import 'compontes/EmptyTab.dart';
import 'compontes/postTitle.dart';
import 'package:instagram_clone/src/compontes/ToastHelper.dart';
import '../../utils/number_helper.dart';
import '../../utils/share_helper.dart';

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
  late final TabController _tabController;
  AppUser? _fetchedUser;
  List<Post> _userPosts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    debugPrint('Starting _fetchProfile...');
    setState(() {
      _isLoading = true;
    });
    try {
      final bool isCurrent = _isCurrentUser;
      final String? targetId = isCurrent ? null : widget.user.id;
      debugPrint('_fetchProfile targetId: $targetId');
      final user = await ApiService.instance.getUserProfile(targetId);
      debugPrint('_fetchProfile fetched user profile successfully.');
      if (mounted) {
        widget.feedService.updateUser(user);
        if (isCurrent) {
          widget.authService?.syncCurrentUser(user);
        }
        setState(() {
          _fetchedUser = user;
        });
      }

      if (_fetchedUser?.isPrivate == true && !isCurrent) {
        debugPrint('_fetchProfile: User is private, skipping posts fetch.');
        _isLoading = false;
        return;
      }
      // Fetch posts after fetching user profile so the grid can display them
      debugPrint('_fetchProfile fetching posts...');
      final posts = await ApiService.instance.getUserPosts(targetId);
      debugPrint('_fetchProfile fetched ${posts.length} posts.');
      if (mounted) {
        setState(() {
          _userPosts = posts;
        });
      }
    } catch (e) {
      debugPrint('Failed to fetch profile: $e');
    } finally {
      debugPrint('Ending _fetchProfile...');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  FeedService get feedService => widget.feedService;

  AppUser get _displayUser {
    final currentUser = widget.authService?.currentUser;
    if (currentUser != null && currentUser.id == widget.user.id) {
      return _fetchedUser ?? currentUser;
    }
    return _fetchedUser ?? widget.user;
  }

  bool get _isCurrentUser {
    final currentUserId = widget.authService?.currentUser?.id;
    return currentUserId != null && currentUserId == widget.user.id;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listenable = Listenable.merge([feedService, widget.authService]);
    return Scaffold(
      backgroundColor: context.surfaceColor,
      appBar: AppBar(
        title: AnimatedBuilder(
          animation: listenable,
          builder: (context, _) {
            final displayUser = _displayUser;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (displayUser.isPrivate)
                  Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(
                      Icons.lock_outline,
                      size: 16,
                      color: context.textPrimaryColor,
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
        actions: _isCurrentUser
            ? [
                IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => _showMenuSheet(context),
                ),
              ]
            : null,
      ),
      body: AnimatedBuilder(
        animation: listenable,
        builder: (context, _) {
          final displayUser = _displayUser;
          final liveUser = feedService.userById(displayUser.id) ?? displayUser;
          final posts = _userPosts;
          final isFollowing = widget.authService?.currentUser == null
              ? false
              : feedService.isFollowing(
                  widget.authService!.currentUser!.id,
                  displayUser.id,
                );

          final isPrivateAndHidden =
              displayUser.isPrivate && !_isCurrentUser && !isFollowing;

          final isLoading = _isLoading;
          if (isLoading && posts.isEmpty) {
            return const Skeletonizer(
              enabled: true,
              enableSwitchAnimation: true,
              child: ProfileSkeleton(),
            );
          }

          return Skeletonizer(
            enabled: isLoading,
            enableSwitchAnimation: true,
            child: RefreshIndicator(
              onRefresh: () async {
                await _fetchProfile();
                if (_displayUser.isPrivate) {
                  return;
                }
                Future.delayed(const Duration(seconds: 5));
                await feedService.refreshFeed();
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
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
                            Stat(
                              label: formatCount(
                                liveUser.postsCount > posts.length
                                    ? liveUser.postsCount
                                    : posts.length,
                              ),
                              value: 'Posts',
                            ),
                            Stat(
                              label: formatCount(liveUser.followers),
                              value: 'Followers',
                            ),
                            Stat(
                              label: formatCount(liveUser.following),
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
                      style: TextStyle(color: context.textSecondaryColor),
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
                                side: BorderSide(
                                  color: context.borderColor,
                                  width: 0.8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                padding: EdgeInsets.zero,
                              ),
                              child: Text(
                                'Edit profile',
                                style: TextStyle(
                                  color: context.textPrimaryColor,
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
                              onPressed: () => ShareHelper.copyProfileLink(
                                context,
                                displayUser.username,
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: context.borderColor,
                                  width: 0.8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                padding: EdgeInsets.zero,
                              ),
                              child: Text(
                                'Share profile',
                                style: TextStyle(
                                  color: context.textPrimaryColor,
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
                          side: BorderSide(
                            color: context.borderColor,
                            width: 0.8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: Text(
                          _buttonLabel(isFollowing),
                          style: TextStyle(
                            color: context.textPrimaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  if (isPrivateAndHidden)
                    Container(
                      height: 300,
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lock_outline,
                            size: 64,
                            color: context.textSecondaryColor,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'This account is private',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: context.textPrimaryColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Follow this account to see their photos and videos.',
                            style: TextStyle(
                              fontSize: 14,
                              color: context.textSecondaryColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else ...[
                    _buildTabBar(),
                    SizedBox(
                      height: 420,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildPostsTab(posts),
                          _buildReelsTab(posts),
                          _buildTaggedTab(feedService.posts, displayUser),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: context.borderColor, width: 0.5),
        ),
      ),
      child: TabBar(
        controller: _tabController,
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
      itemBuilder: (context, index) => PostTile(
        feedService: feedService,
        post: posts[index],
        posts: posts,
        heroTag: 'posts_${posts[index].id}',
      ),
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
      itemBuilder: (context, index) => PostTile(
        feedService: feedService,
        post: reels[index],
        posts: reels,
        heroTag: 'reels_${reels[index].id}',
      ),
    );
  }

  Widget _buildTaggedTab(List<Post> allPosts, AppUser displayUser) {
    final taggedPosts = allPosts.where((p) {
      return p.taggedUsers.any(
        (u) =>
            u.id == displayUser.id ||
            u.username.toLowerCase() == displayUser.username.toLowerCase(),
      );
    }).toList();

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

  String _buttonLabel(bool isFollowing) {
    if (_isCurrentUser) return 'Edit profile';
    return isFollowing ? 'Following' : 'Follow';
  }

  void _openEditProfile(BuildContext context) {
    final auth = widget.authService ?? AppScope.of(context).authService;
    final currentUser = auth.currentUser;

    if (currentUser == null) {
      return;
    }

    try {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              EditProfileScreen(authService: auth, user: currentUser),
        ),
      );
    } catch (e, t) {
      // Ignored
    }
  }

  void _toggleFollow(BuildContext context) {
    final current = widget.authService?.currentUser;
    if (current == null) return;
    feedService.toggleFollow(current.id, _displayUser.id);
    final isFollowingNow = feedService.isFollowing(current.id, _displayUser.id);
    if (isFollowingNow) {
      ToastHelper.showToast(context, "Following ${_displayUser.username}");
    } else {
      ToastHelper.showToast(context, "Unfollowed ${_displayUser.username}");
    }
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
                color: context.borderColor,
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
      ListenableBuilder(
        listenable: AppScope.of(ctx).themeService,
        builder: (context, _) {
          final themeService = AppScope.of(ctx).themeService;
          final isDark = themeService.isDarkMode;
          return ListTile(
            leading: AnimatedSwitcher(
              duration: const Duration(milliseconds: 450),
              switchInCurve: Curves.easeOutBack,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (Widget child, Animation<double> animation) {
                return RotationTransition(
                  turns: Tween<double>(begin: 0.5, end: 1.0).animate(animation),
                  child: ScaleTransition(
                    scale: Tween<double>(
                      begin: 0.5,
                      end: 1.0,
                    ).animate(animation),
                    child: FadeTransition(opacity: animation, child: child),
                  ),
                );
              },
              child: Icon(
                isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                key: ValueKey<bool>(isDark),
                color: isDark ? Colors.amber : Colors.orangeAccent,
              ),
            ),
            title: const Text(
              'Dark Mode',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            trailing: Switch(
              value: isDark,
              onChanged: (val) {
                themeService.toggleTheme();
              },
            ),
          );
        },
      ),
      ListTile(
        leading: const Icon(Icons.bookmark_border),
        title: const Text(
          'Saved',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BookmarksScreen(feedService: feedService),
            ),
          );
        },
      ),
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
          _confirmLogout();
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
          _confirmDeleteAccount();
        },
      ),
    ];
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
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
      if (!mounted) return;
      ToastHelper.showToast(context, "Logged out successfully.");
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
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
      try {
        await widget.authService?.deleteAccount();
        if (!mounted) return;
        ToastHelper.showToast(context, "Account deleted successfully.");
        Navigator.of(context).popUntil((route) => route.isFirst);
      } catch (e) {
        if (!mounted) return;
        ToastHelper.showToast(
          context,
          "Failed to delete account. Please try again.",
        );
      }
    }
  }
}
