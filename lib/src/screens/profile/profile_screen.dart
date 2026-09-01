import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../adaptive_colors.dart';
import '../../app.dart';

import '../../constants.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/feed_service.dart';
import '../../blocs/profile/profile_cubit.dart';
import '../../blocs/profile/profile_state.dart';
import '../../widgets/ui_skeletons.dart';
import 'edit_profile_screen.dart';
import 'changePassword.dart';
import 'bookmarks/bookmarks_screen.dart';
import 'widgets/profile_header_widget.dart';
import 'widgets/private_profile_widget.dart';
import 'widgets/profile_tabs_widget.dart';
import 'package:instagram_clone/src/components/ToastHelper.dart';

class ProfileScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProfileCubit(
        initialUser: user,
        feedService: feedService,
        authService: authService,
      )..fetchProfile(),
      child: _ProfileScreenContent(
        feedService: feedService,
        authService: authService,
      ),
    );
  }
}

class _ProfileScreenContent extends StatefulWidget {
  final FeedService feedService;
  final AuthService? authService;

  const _ProfileScreenContent({
    required this.feedService,
    required this.authService,
  });

  @override
  State<_ProfileScreenContent> createState() => _ProfileScreenContentState();
}

class _ProfileScreenContentState extends State<_ProfileScreenContent>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        final displayUser = state.user;
        final liveUser = widget.feedService.userById(displayUser.id) ?? displayUser;
        final posts = state.posts;
        final isCurrentUser = state.isCurrentUser;
        
        final isFollowing = widget.authService?.currentUser == null
            ? false
            : widget.feedService.isFollowing(
                widget.authService!.currentUser!.id,
                displayUser.id,
              );

        final isPrivateAndHidden =
            displayUser.isPrivate && !isCurrentUser && !isFollowing;

        return Scaffold(
          backgroundColor: context.surfaceColor,
          appBar: AppBar(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (displayUser.isPrivate)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
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
            ),
            centerTitle: false,
            actions: isCurrentUser
                ? [
                    IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () => _showMenuSheet(context, isCurrentUser),
                    ),
                  ]
                : null,
          ),
          body: ListenableBuilder(
            listenable: widget.feedService,
            builder: (context, _) {
              if (state.isLoading && posts.isEmpty) {
                return const Skeletonizer(
                  enabled: true,
                  enableSwitchAnimation: true,
                  child: ProfileSkeleton(),
                );
              }

              return Skeletonizer(
                enabled: state.isLoading,
                enableSwitchAnimation: true,
                child: RefreshIndicator(
                  onRefresh: () => context.read<ProfileCubit>().refreshProfile(),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      ProfileHeaderWidget(
                        displayUser: displayUser,
                        liveUser: liveUser,
                        postsCount: posts.length,
                        isCurrentUser: isCurrentUser,
                        isFollowing: isFollowing,
                        onEditProfile: () => _openEditProfile(context),
                        onToggleFollow: () => _toggleFollow(context, displayUser),
                      ),
                      if (isPrivateAndHidden)
                        const PrivateProfileWidget()
                      else
                        ProfileTabsWidget(
                          tabController: _tabController,
                          posts: posts,
                          feedService: widget.feedService,
                          displayUser: displayUser,
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
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

  void _toggleFollow(BuildContext context, AppUser displayUser) {
    final current = widget.authService?.currentUser;
    if (current == null) return;
    widget.feedService.toggleFollow(current.id, displayUser.id);
    final isFollowingNow = widget.feedService.isFollowing(current.id, displayUser.id);
    if (isFollowingNow) {
      ToastHelper.showToast(context, "Following ${displayUser.username}");
    } else {
      ToastHelper.showToast(context, "Unfollowed ${displayUser.username}");
    }
  }

  void _showMenuSheet(BuildContext context, bool isCurrentUser) {
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
            if (isCurrentUser) ..._accountMenuItems(ctx),
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
              builder: (context) => BookmarksScreen(feedService: widget.feedService),
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
