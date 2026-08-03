import 'package:flutter/material.dart';

import '../../constants.dart';
import '../../models/post.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/feed_service.dart';
import '../profile/profile_screen.dart';
import '../reels/reels_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({
    super.key,
    required this.feedService,
    this.authService,
  });

  final FeedService feedService;
  final AuthService? authService;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value.trim()),
                decoration: InputDecoration(
                  hintText: 'Search',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        ),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            Expanded(
              child: AnimatedBuilder(
                animation: widget.feedService,
                builder: (context, _) {
                  if (_query.isNotEmpty) {
                    return _buildResults();
                  }
                  return _buildGrid();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<AppUser> get _allUsers {
    final seen = <String>{};
    final users = <AppUser>[];
    for (final post in widget.feedService.posts) {
      if (seen.add(post.author.id)) users.add(post.author);
    }
    return users;
  }

  Widget _buildResults() {
    final matches = _allUsers.where(
      (u) => u.username.toLowerCase().contains(_query.toLowerCase()) ||
          u.fullName.toLowerCase().contains(_query.toLowerCase()),
    );
    if (matches.isEmpty) {
      return const Center(child: Text('No results', style: TextStyle(color: AppColors.textSecondary)));
    }
    return ListView.builder(
      itemCount: matches.length,
      itemBuilder: (context, index) {
        final user = matches.elementAt(index);
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: user.avatarUrl.isEmpty ? null : NetworkImage(user.avatarUrl),
            child: user.avatarUrl.isEmpty ? const Icon(Icons.person) : null,
          ),
          title: Text(user.username),
          subtitle: Text(user.fullName),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ProfileScreen(
                feedService: widget.feedService,
                user: user,
                authService: widget.authService,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGrid() {
    final posts = widget.feedService.posts;
    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemCount: posts.length,
      itemBuilder: (context, index) =>
          _SearchTile(feedService: widget.feedService, post: posts[index]),
    );
  }
}

class _SearchTile extends StatelessWidget {
  const _SearchTile({required this.feedService, required this.post});

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
