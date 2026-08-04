import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../../constants.dart';
import '../../models/post.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/feed_service.dart';
import '../profile/profile_screen.dart';
import '../reels/reels_screen.dart';

// ── Category chip data ────────────────────────────────────────────────────────

const _kCategories = <(IconData?, String)>[
  (null, 'IGTV'),
  (null, 'Shop'),
  (null, 'Style'),
  (null, 'Sports'),
  (null, 'Auto'),
  (null, 'Music'),
  (null, 'Travel'),
  (null, 'Food'),
];

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
  final FocusNode _focusNode = FocusNode();
  String _query = '';
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _focused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    _focusNode.unfocus();
    setState(() {
      _query = '';
      _focused = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Search bar row ────────────────────────────────────────
            _buildSearchBar(),

            // ── Category chips (only when not searching) ──────────────
            if (_query.isEmpty && !_focused) _buildCategoryChips(),

            // ── Body ──────────────────────────────────────────────────
            Expanded(
              child: AnimatedBuilder(
                animation: widget.feedService,
                builder: (context, _) {
                  if (_query.isNotEmpty || _focused) {
                    return _buildResults();
                  }
                  return _buildExploreGrid();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Search bar ────────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 36,
              child: TextField(
                controller: _searchController,
                focusNode: _focusNode,
                onChanged: (v) => setState(() => _query = v.trim()),
                textAlignVertical: TextAlignVertical.center,
                style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search',
                  hintStyle: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                  ),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(left: 10, right: 6),
                    child: Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                  ),
                  prefixIconConstraints: const BoxConstraints(),
                  suffixIcon: _query.isNotEmpty
                      ? GestureDetector(
                          onTap: _clearSearch,
                          child: const Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: Icon(Icons.cancel, color: AppColors.textSecondary, size: 18),
                          ),
                        )
                      : null,
                  suffixIconConstraints: const BoxConstraints(),
                  filled: true,
                  fillColor: const Color(0xFFEFEFEF),
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
          // Camera / QR icon (right side) — only when not focused
          if (!_focused) ...[
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () {},
              child: const Icon(Icons.qr_code_scanner_outlined,
                  size: 26, color: AppColors.textPrimary),
            ),
          ] else ...[
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _clearSearch,
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Category chips ────────────────────────────────────────────────────────

  Widget _buildCategoryChips() {
    return Container(
      color: Colors.white,
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        itemCount: _kCategories.length,
        itemBuilder: (context, i) {
          final (icon, label) = _kCategories[i];
          return Container(
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
            decoration: BoxDecoration(
              color: const Color(0xFFEFEFEF),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 14, color: AppColors.textPrimary),
                  const SizedBox(width: 4),
                ],
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── User-search results ───────────────────────────────────────────────────

  List<AppUser> get _allUsers {
    final seen = <String>{};
    final users = <AppUser>[];
    for (final post in widget.feedService.posts) {
      if (seen.add(post.author.id)) users.add(post.author);
    }
    return users;
  }

  Widget _buildResults() {
    final q = _query.toLowerCase();
    final matches = q.isEmpty
        ? _allUsers
        : _allUsers.where(
            (u) =>
                u.username.toLowerCase().contains(q) ||
                u.fullName.toLowerCase().contains(q),
          );

    if (matches.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 52, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text(
              'No results found',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
              ),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: matches.length,
      separatorBuilder: (_, i) =>
          const Divider(height: 0, thickness: 0.5, indent: 72),
      itemBuilder: (context, index) {
        final user = matches.elementAt(index);
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.border,
            backgroundImage:
                user.avatarUrl.isNotEmpty ? NetworkImage(user.avatarUrl) : null,
            child: user.avatarUrl.isEmpty
                ? const Icon(Icons.person, color: AppColors.textSecondary)
                : null,
          ),
          title: Text(
            user.username,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
          subtitle: Text(
            user.fullName,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
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

  // ── Instagram Explore-style varied grid ───────────────────────────────────
  //
  // Pattern (repeating every 6 posts, 2 rows):
  //   Row A: [big 2×2] [small] [small]    → posts 0,1,2
  //   Row B: [small]   [small] [big 2×2]  → posts 3,4,5
  //
  // We use a CustomScrollView + SliverList of Row widgets for precise control.

  Widget _buildExploreGrid() {
    final posts = widget.feedService.posts;

    if (posts.isEmpty) {
      return const Center(
        child: Text(
          'Nothing to explore yet',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    final random = Random(42);

    // Generate big tile positions once
    final Set<int> bigTiles = {};
    final Map<int, bool> bigLeft = {};

    int index = random.nextInt(3);

    while (index < posts.length) {
      bigTiles.add(index);
      bigLeft[index] = random.nextBool();

      // Keep 6–7 normal posts between big tiles
      index += 7 + random.nextInt(2);
    }

    // Generate cover tile positions (2×2 collage of 4 posts)
    final Set<int> coverTiles = {};
    int coverIndex = 2 + random.nextInt(4);
    while (coverIndex + 3 < posts.length) {
      coverTiles.add(coverIndex);
      coverIndex += 11 + random.nextInt(3);
    }

    // Build flat list of tile specs; a cover tile consumes 4 posts
    final specs = <_TileSpec>[];
    for (var i = 0; i < posts.length;) {
      if (coverTiles.contains(i)) {
        specs.add(_TileSpec.cover(
          posts.sublist(i, (i + 4).clamp(0, posts.length)),
        ));
        i += 4;
      } else {
        specs.add(_TileSpec.single(posts[i], postIndex: i));
        i += 1;
      }
    }

    return MasonryGridView.count(
      crossAxisCount: 3,
      mainAxisSpacing: 2,
      crossAxisSpacing: 2,
      itemCount: specs.length,
      itemBuilder: (context, index) {
        final spec = specs[index];
        final large = spec.single != null && bigTiles.contains(spec.postIndex);

        return _ExploreTile(
          spec: spec,
          feedService: widget.feedService,
          large: large,
          gap: 2,
        );
      },
    );
  }
}

class _TileSpec {
  const _TileSpec.single(Post post, {required this.postIndex})
      : single = post,
        cover = null;

  const _TileSpec.cover(List<Post> posts)
      : single = null,
        cover = posts,
        postIndex = null;

  final Post? single;
  final List<Post>? cover;
  final int? postIndex;
}

// ── Explore tile ──────────────────────────────────────────────────────────────

class _ExploreTile extends StatelessWidget {
  const _ExploreTile({
    required this.spec,
    required this.feedService,
    required this.large,
    required this.gap,
  });

  final _TileSpec spec;
  final FeedService feedService;
  final bool large;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final cover = spec.cover;

    if (cover != null) {
      return _buildCover(cover);
    }

    final post = spec.single!;
    return GestureDetector(
      onTap: () {
        if (!post.isVideo) return;

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ReelsScreen(
              feedService: feedService,
              currentUser: post.author,
            ),
          ),
        );
      },
      child: AspectRatio(
        aspectRatio: large ? 1 / 2 : 1,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              post.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                color: AppColors.border,
                child: const Icon(
                  Icons.image_not_supported_outlined,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            if (post.isVideo)
              const Positioned(
                top: 6,
                right: 6,
                child: Icon(
                  Icons.play_circle_fill,
                  color: Colors.white,
                  size: 22,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCover(List<Post> posts) {
    final count = posts.length;
    return AspectRatio(
      aspectRatio: 1,
      child: count == 1
          ? _coverImage(posts[0])
          : count == 2
              ? Row(
                  children: [
                    Expanded(child: _coverImage(posts[0])),
                    const SizedBox(width: 2),
                    Expanded(child: _coverImage(posts[1])),
                  ],
                )
              : count == 3
                  ? Row(
                      children: [
                        Expanded(child: _coverImage(posts[0])),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Column(
                            children: [
                              Expanded(child: _coverImage(posts[1])),
                              const SizedBox(height: 2),
                              Expanded(child: _coverImage(posts[2])),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(child: _coverImage(posts[0])),
                              const SizedBox(width: 2),
                              Expanded(child: _coverImage(posts[1])),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(child: _coverImage(posts[2])),
                              const SizedBox(width: 2),
                              Expanded(child: _coverImage(posts[3])),
                            ],
                          ),
                        ),
                      ],
                    ),
    );
  }

  Widget _coverImage(Post post) {
    return Image.network(
      post.imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Container(
        color: AppColors.border,
        child: const Icon(
          Icons.image_not_supported_outlined,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
