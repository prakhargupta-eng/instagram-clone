import 'package:flutter/material.dart';

import '../../constants.dart';
import '../../models/post.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/feed_service.dart';
import '../../widgets/avatar.dart';
import '../reels/reels_screen.dart';
import 'edit_profile_screen.dart';

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

  AppUser get _displayUser => authService?.currentUser ?? user;
  bool get _isCurrentUser => authService != null;

  @override
  Widget build(BuildContext context) {
    final listenable = Listenable.merge([feedService, authService]);
    return Scaffold(
      appBar: AppBar(
        title: AnimatedBuilder(
          animation: listenable,
          builder: (context, _) =>
              Text(_displayUser.username, style: const TextStyle(fontWeight: FontWeight.bold)),
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
          final posts =
              feedService.posts.where((p) => p.author.id == displayUser.id).toList();
          final isFollowing = authService == null
              ? false
              : feedService.isFollowing(authService!.currentUser!.id, displayUser.id);
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
                        _Stat(label: '${posts.length}', value: 'Posts'),
                        _Stat(label: '${displayUser.followers}', value: 'Followers'),
                        _Stat(label: '${displayUser.following}', value: 'Following'),
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
              if (displayUser.bio.isNotEmpty)
                Text(displayUser.bio, style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              SizedBox(
                height: 34,
                child: OutlinedButton(
                  onPressed: _isCurrentUser
                      ? () => _openEditProfile(context)
                      : () => _toggleFollow(context),
                  child: Text(
                    _buttonLabel(isFollowing),
                    style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (posts.isNotEmpty)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 2,
                    crossAxisSpacing: 2,
                  ),
                  itemCount: posts.length,
                  itemBuilder: (context, index) =>
                      _PostTile(feedService: feedService, post: posts[index]),
                ),
            ],
          );
        },
      ),
    );
  }

  String _buttonLabel(bool isFollowing) {
    if (_isCurrentUser) return 'Edit profile';
    return isFollowing ? 'Following' : 'Follow';
  }

  void _openEditProfile(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(
          authService: authService!,
          user: authService!.currentUser!,
        ),
      ),
    );
  }

  void _toggleFollow(BuildContext context) {
    final current = authService?.currentUser;
    if (current == null) return;
    feedService.toggleFollow(current.id, _displayUser.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          feedService.isFollowing(current.id, _displayUser.id)
              ? 'Following ${_displayUser.username}'
              : 'Unfollowed ${_displayUser.username}',
        ),
        duration: const Duration(seconds: 1),
      ),
    );
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
        leading: const Icon(Icons.logout),
        title: const Text(AppStrings.logout, style: TextStyle(fontWeight: FontWeight.w500)),
        onTap: () {
          Navigator.of(ctx).pop();
          _confirmLogout(ctx);
        },
      ),
      const Divider(height: 1),
      ListTile(
        leading: const Icon(Icons.delete_outline, color: AppColors.error),
        title: const Text(AppStrings.deleteAccount,
            style: TextStyle(fontWeight: FontWeight.w500, color: AppColors.error)),
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
      await authService?.logout();
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
            child: const Text(AppStrings.deleteAccount,
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await authService?.deleteAccount();
    }
  }
}


class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(value, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _PostTile extends StatelessWidget {
  const _PostTile({required this.feedService, required this.post});

  final FeedService feedService;
  final Post post;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (!post.isVideo) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => ReelsScreen(
              feedService: feedService,
              currentUser: post.author,
              initialIndex: 0,
            ),
          ),
        );
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            post.imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              color: AppColors.border,
              child: const Icon(Icons.image_not_supported_outlined, color: AppColors.textSecondary),
            ),
          ),
          if (post.isVideo)
            const Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.play_circle, color: AppColors.white, size: 20),
              ),
            ),
        ],
      ),
    );
  }
}
