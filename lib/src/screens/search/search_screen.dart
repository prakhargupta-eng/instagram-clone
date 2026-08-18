import 'dart:math';

import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../adaptive_colors.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../../app.dart';
import '../../constants.dart';
import '../../models/post.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/feed_service.dart';

import 'search_view_model.dart';
import '../profile/profile_screen.dart';
import '../profile/details_screen.dart';
import '../reels/reels_screen.dart';
import '../../widgets/media_image.dart';
import '../../widgets/ui_skeletons.dart';
import '../../widgets/avatar.dart';
// ── Category chip data ────────────────────────────────────────────────────────

const _kCategories = <(IconData?, String)>[
  (null, 'All'),
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
  const SearchScreen({super.key, required this.feedService, this.authService});

  final FeedService feedService;
  final AuthService? authService;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with TickerProviderStateMixin {
  late final SearchViewModel _viewModel;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _viewModel = SearchViewModel(feedService: widget.feedService);
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([widget.feedService, _viewModel]),
      builder: (context, _) {
        final query = _viewModel.query;
        final focused = _viewModel.isFocused;
        final showTabs = query.isNotEmpty || focused;

        return Scaffold(
          backgroundColor: context.backgroundColor,
          body: SafeArea(
            child: Column(
              children: [
                // ── Search bar row ────────────────────────────────────────
                _buildSearchBar(),

                // ── Tab Bar (only when searching or focused) ──────────────
                if (showTabs) _buildTabBar(),

                // ── Category chips (only when not searching) ──────────────
                if (!showTabs) _buildCategoryChips(),

                // ── Body ──────────────────────────────────────────────────
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final isLoading = widget.feedService.isLoading;
                      return Skeletonizer(
                        enabled: isLoading,
                        enableSwitchAnimation: true,
                        child: showTabs
                            ? _buildTabbedResults()
                            : _buildExploreGrid(),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Search bar ────────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    final isDarkTheme = isDark(context);
    return Container(
      color: context.backgroundColor,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 36,
              child: TextField(
                controller: _viewModel.searchController,
                focusNode: _viewModel.focusNode,
                onChanged: (v) {
                  _viewModel.onQueryChanged(v, (idx) {
                    if (_tabController.index != idx) {
                      _tabController.animateTo(idx);
                    }
                  });
                },
                onSubmitted: (v) => _viewModel.addRecentSearch(v),
                textAlignVertical: TextAlignVertical.center,
                style: TextStyle(fontSize: 15, color: context.textPrimaryColor),
                decoration: InputDecoration(
                  hintText: 'Search',
                  hintStyle: TextStyle(
                    color: context.textSecondaryColor,
                    fontSize: 15,
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 10, right: 6),
                    child: Icon(
                      Icons.search,
                      color: context.textSecondaryColor,
                      size: 20,
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints(),
                  suffixIcon: _viewModel.query.isNotEmpty
                      ? GestureDetector(
                          onTap: () => _viewModel.clearSearch(
                            (idx) => _tabController.animateTo(idx),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Icon(
                              Icons.cancel,
                              color: context.textSecondaryColor,
                              size: 18,
                            ),
                          ),
                        )
                      : null,
                  suffixIconConstraints: const BoxConstraints(),
                  filled: true,
                  fillColor: isDarkTheme
                      ? const Color(0xFF262626)
                      : const Color(0xFFEFEFEF),
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
          if (!_viewModel.isFocused) ...[
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () {},
              child: Icon(
                Icons.qr_code_scanner_outlined,
                size: 26,
                color: context.textPrimaryColor,
              ),
            ),
          ] else ...[
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => _viewModel.clearSearch(
                (idx) => _tabController.animateTo(idx),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: context.textPrimaryColor,
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

  // ── Tab Bar ───────────────────────────────────────────────────────────────

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: context.backgroundColor,
        border: Border(
          bottom: BorderSide(color: context.borderColor, width: 0.5),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: context.textPrimaryColor,
        labelColor: context.textPrimaryColor,
        unselectedLabelColor: context.textSecondaryColor,
        indicatorWeight: 1.5,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        tabs: const [
          Tab(text: 'Top'),
          Tab(text: 'Accounts'),
          Tab(text: 'Tags'),
          Tab(text: 'Places'),
        ],
      ),
    );
  }

  // ── Category chips ────────────────────────────────────────────────────────

  Widget _buildCategoryChips() {
    final isDarkTheme = isDark(context);
    return Container(
      color: context.backgroundColor,
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        itemCount: _kCategories.length,
        itemBuilder: (context, i) {
          final (icon, label) = _kCategories[i];
          final isSelected = _viewModel.selectedCategory == label;
          return GestureDetector(
            onTap: () => _viewModel.selectCategory(label),
            child: Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              decoration: BoxDecoration(
                color: isSelected
                    ? context.textPrimaryColor
                    : isDarkTheme
                    ? const Color(0xFF262626)
                    : const Color(0xFFEFEFEF),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: 14,
                      color: isSelected
                          ? context.backgroundColor
                          : context.textPrimaryColor,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? context.backgroundColor
                          : context.textPrimaryColor,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Tab Views ─────────────────────────────────────────────────────────────

  Widget _buildTabbedResults() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildTopTab(),
        _buildAccountsTab(),
        _buildTagsTab(),
        _buildPlacesTab(),
      ],
    );
  }

  Widget _buildTopTab() {
    if (_viewModel.query.isEmpty) {
      return _buildRecentSearchesSection();
    }

    final matchedUsers = _viewModel.filteredUsers.take(3).toList();
    final matchedTags = _viewModel.filteredTags.take(3).toList();
    final matchedLocs = _viewModel.filteredLocations.take(3).toList();

    if (matchedUsers.isEmpty && matchedTags.isEmpty && matchedLocs.isEmpty) {
      return _buildNoResultsPlaceholder();
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        if (matchedUsers.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Accounts',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          ...matchedUsers.map((user) => _buildUserListTile(user)),
          const SizedBox(height: 8),
        ],
        if (matchedTags.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Tags',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          ...matchedTags.map((tag) => _buildTagListTile(tag)),
          const SizedBox(height: 8),
        ],
        if (matchedLocs.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Places',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          ...matchedLocs.map((loc) => _buildLocationListTile(loc)),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildRecentSearchesSection() {
    final hasRecent = _viewModel.recentSearches.isNotEmpty;
    final sugUsers = _viewModel.suggestedUsers;
    final sugTags = _viewModel.suggestedTags;
    final sugLocs = _viewModel.suggestedLocations;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        if (hasRecent) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    _viewModel.clearRecentSearches();
                  },
                  child: const Text(
                    'Clear All',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ..._viewModel.recentSearches.map((item) {
            final isTag = item.startsWith('#');
            final isLoc = !isTag && _viewModel.allLocations.contains(item);
            final isUser = !isTag && !isLoc;

            IconData icon = Icons.history;
            if (isTag) icon = Icons.tag;
            if (isLoc) icon = Icons.location_on_outlined;

            return ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 0,
              ),
              leading: isUser
                  ? _buildRecentUserAvatar(item)
                  : Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Icon(
                        icon,
                        color: AppColors.textSecondary,
                        size: 18,
                      ),
                    ),
              title: Text(
                item,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              trailing: IconButton(
                icon: const Icon(
                  Icons.close,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                onPressed: () {
                  _viewModel.removeRecentSearch(item);
                },
              ),
              onTap: () => _viewModel.selectQuery(
                item,
                (idx) => _tabController.animateTo(idx),
              ),
            );
          }),
          const Divider(height: 24, thickness: 0.5, indent: 16, endIndent: 16),
        ],

        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Suggested for You',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (sugUsers.isNotEmpty)
          ...sugUsers.map((user) => _buildSuggestedUserTile(user)),
        if (sugTags.isNotEmpty)
          ...sugTags.map((tag) => _buildSuggestedTagTile(tag)),
        if (sugLocs.isNotEmpty)
          ...sugLocs.map((loc) => _buildSuggestedLocationTile(loc)),
        if (sugUsers.isEmpty && sugTags.isEmpty && sugLocs.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              'No suggestions available',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
      ],
    );
  }

  Widget _buildSuggestedUserTile(AppUser user) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      leading: Avatar(url: user.avatarUrl, radius: 18),
      title: Text(
        user.username,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        'Popular Account • ${user.followers} followers',
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        size: 16,
        color: AppColors.textSecondary,
      ),
      onTap: () => _viewModel.selectQuery(
        user.username,
        (idx) => _tabController.animateTo(idx),
      ),
    );
  }

  Widget _buildSuggestedTagTile(String tag) {
    final count = widget.feedService.posts
        .where((p) => p.caption.toLowerCase().contains(tag.toLowerCase()))
        .length;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
        ),
        child: const Icon(Icons.trending_up, color: Colors.blue, size: 18),
      ),
      title: Text(
        tag,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        'Trending Tag • $count ${count == 1 ? "post" : "posts"}',
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        size: 16,
        color: AppColors.textSecondary,
      ),
      onTap: () =>
          _viewModel.selectQuery(tag, (idx) => _tabController.animateTo(idx)),
    );
  }

  Widget _buildSuggestedLocationTile(String location) {
    final count = widget.feedService.posts
        .where((p) => p.location == location)
        .length;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
        ),
        child: const Icon(
          Icons.location_on_outlined,
          color: Colors.redAccent,
          size: 18,
        ),
      ),
      title: Text(
        location,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        'Popular Place • $count ${count == 1 ? "post" : "posts"}',
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        size: 16,
        color: AppColors.textSecondary,
      ),
      onTap: () => _viewModel.selectQuery(
        location,
        (idx) => _tabController.animateTo(idx),
      ),
    );
  }

  Widget _buildRecentUserAvatar(String username) {
    final user = _viewModel.allUsers.firstWhere(
      (u) => u.username == username,
      orElse: () => AppUser(
        id: '',
        username: username,
        avatarUrl: '',
        fullName: '',
        email: '',
        bio: '',
      ),
    );
    return Avatar(url: user.avatarUrl, radius: 18);
  }

  Widget _buildAccountsTab() {
    final matches = _viewModel.filteredUsers.toList();
    if (matches.isEmpty) return _buildNoResultsPlaceholder();

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: matches.length,
      separatorBuilder: (_, i) =>
          const Divider(height: 0, thickness: 0.5, indent: 72),
      itemBuilder: (context, index) {
        return _buildUserListTile(matches[index]);
      },
    );
  }

  Widget _buildUserListTile(AppUser user) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Avatar(url: user.avatarUrl, radius: 20),
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
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
      ),
      onTap: () {
        print("user:-*\$#\$*#*\$ ${user.toJson()}");
        _viewModel.addRecentSearch(user.username);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProfileScreen(
              feedService: widget.feedService,
              user: user,
              authService: widget.authService,
            ),
          ),
        );
      },
    );
  }

  Widget _buildTagsTab() {
    final matches = _viewModel.filteredTags.toList();
    if (matches.isEmpty) return _buildNoResultsPlaceholder();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: matches.length,
      itemBuilder: (context, index) {
        return _buildTagListTile(matches[index]);
      },
    );
  }

  Widget _buildTagListTile(String tag) {
    final count = widget.feedService.posts
        .where((p) => p.caption.toLowerCase().contains(tag.toLowerCase()))
        .length;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
        ),
        child: const Icon(Icons.tag, color: AppColors.textPrimary, size: 20),
      ),
      title: Text(
        tag,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        '$count ${count == 1 ? "post" : "posts"}',
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
      ),
      onTap: () {
        _viewModel.addRecentSearch(tag);
        _viewModel.selectQuery(tag, (idx) => _tabController.animateTo(idx));
      },
    );
  }

  Widget _buildPlacesTab() {
    final matches = _viewModel.filteredLocations.toList();
    if (matches.isEmpty) return _buildNoResultsPlaceholder();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: matches.length,
      itemBuilder: (context, index) {
        return _buildLocationListTile(matches[index]);
      },
    );
  }

  Widget _buildLocationListTile(String location) {
    final count = widget.feedService.posts
        .where((p) => p.location == location)
        .length;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
        ),
        child: const Icon(
          Icons.location_on_outlined,
          color: AppColors.textPrimary,
          size: 20,
        ),
      ),
      title: Text(
        location,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        '$count ${count == 1 ? "post" : "posts"}',
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
      ),
      onTap: () {
        _viewModel.addRecentSearch(location);
        _viewModel.selectQuery(
          location,
          (idx) => _tabController.animateTo(idx),
        );
      },
    );
  }

  Widget _buildNoResultsPlaceholder() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 52, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          const Text(
            'No results found',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
          ),
        ],
      ),
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
    final bool isCategory = _viewModel.selectedCategory != null;
    final posts = isCategory
        ? _viewModel.categoryPosts
        : widget.feedService.posts;
    final isLoading = isCategory
        ? _viewModel.isCategoryLoading
        : widget.feedService.isLoading;
    if (isLoading && posts.isEmpty) {
      return const ExploreGridSkeleton();
    }

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
        specs.add(
          _TileSpec.cover(posts.sublist(i, (i + 4).clamp(0, posts.length))),
        );
        i += 4;
      } else {
        specs.add(_TileSpec.single(posts[i], postIndex: i));
        i += 1;
      }
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (!_viewModel.isCategoryLoadingMore &&
            scrollInfo.metrics.pixels >=
                scrollInfo.metrics.maxScrollExtent - 500) {
          _viewModel.loadMoreCategoryPosts();
        }
        return false;
      },
      child: MasonryGridView.count(
        crossAxisCount: 3,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
        itemCount: specs.length + (_viewModel.isCategoryLoadingMore ? 3 : 0),
        itemBuilder: (context, index) {
          if (index >= specs.length) {
            return AspectRatio(
              aspectRatio: 1,
              child: Skeletonizer(
                enabled: true,
                child: Container(color: Colors.grey),
              ),
            );
          }

          final spec = specs[index];
          final large =
              spec.single != null && bigTiles.contains(spec.postIndex);

          return _ExploreTile(
            spec: spec,
            feedService: widget.feedService,
            large: large,
            gap: 2,
            allPosts: posts,
          );
        },
      ),
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
    required this.allPosts,
  });

  final _TileSpec spec;
  final FeedService feedService;
  final bool large;
  final double gap;
  final List<Post> allPosts;

  @override
  Widget build(BuildContext context) {
    final cover = spec.cover;

    if (cover != null) {
      return _buildCover(context, cover);
    }

    final post = spec.single!;
    return GestureDetector(
      onTap: () {
        if (post.isVideo) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ReelsScreen(
                feedService: feedService,
                currentUser: post.author,
              ),
            ),
          );
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => DetailsScreen(
                post: post,
                posts: allPosts,
                feedService: feedService,
              ),
            ),
          );
        }
      },
      child: AspectRatio(
        aspectRatio: large ? 1 / 2 : 1,
        child: Stack(
          fit: StackFit.expand,
          children: [
            MediaImage(
              path: post.imageUrl,
              videoUrl: post.isVideo ? post.videoUrl : null,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
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

  Widget _buildCover(BuildContext context, List<Post> posts) {
    final count = posts.length;
    return AspectRatio(
      aspectRatio: 1,
      child: count == 1
          ? _coverImage(context, posts[0])
          : count == 2
          ? Row(
              children: [
                Expanded(child: _coverImage(context, posts[0])),
                const SizedBox(width: 2),
                Expanded(child: _coverImage(context, posts[1])),
              ],
            )
          : count == 3
          ? Row(
              children: [
                Expanded(child: _coverImage(context, posts[0])),
                const SizedBox(width: 2),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(child: _coverImage(context, posts[1])),
                      const SizedBox(height: 2),
                      Expanded(child: _coverImage(context, posts[2])),
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
                      Expanded(child: _coverImage(context, posts[0])),
                      const SizedBox(width: 2),
                      Expanded(child: _coverImage(context, posts[1])),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(child: _coverImage(context, posts[2])),
                      const SizedBox(width: 2),
                      Expanded(child: _coverImage(context, posts[3])),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _coverImage(BuildContext context, Post post) {
    return GestureDetector(
      onTap: () {
        if (post.isVideo) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ReelsScreen(
                feedService: feedService,
                currentUser: post.author,
              ),
            ),
          );
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => DetailsScreen(
                post: post,
                posts: allPosts,
                feedService: feedService,
              ),
            ),
          );
        }
      },
      child: MediaImage(
        path: post.imageUrl,
        videoUrl: post.isVideo ? post.videoUrl : null,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: AppColors.border,
          child: const Icon(
            Icons.image_not_supported_outlined,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
