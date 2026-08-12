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
import '../profile/profile_screen.dart';
import '../reels/reels_screen.dart';
import '../../widgets/media_image.dart';

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
  const SearchScreen({super.key, required this.feedService, this.authService});

  final FeedService feedService;
  final AuthService? authService;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _query = '';
  bool _focused = false;
  late final TabController _tabController;

  final List<String> _recentSearches = [
    '#travel',
    'sarah_j',
    'New York, NY',
    '#photography',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _focusNode.addListener(() {
      setState(() => _focused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    _focusNode.unfocus();
    setState(() {
      _query = '';
      _focused = false;
    });
    _tabController.index = 0;
  }

  void _addRecentSearch(String item) {
    final trimmed = item.trim();
    if (trimmed.isEmpty) return;
    setState(() {
      _recentSearches.remove(trimmed);
      _recentSearches.insert(0, trimmed);
    });
  }

  void _selectQuery(String item) {
    _searchController.text = item;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: item.length),
    );
    setState(() {
      _query = item.trim();
      _addRecentSearch(item);
    });

    final queryStr = item.trim();
    if (queryStr.startsWith('#')) {
      _tabController.animateTo(2); // Tags
    } else if (_allLocations.contains(queryStr)) {
      _tabController.animateTo(3); // Places
    } else if (_allUsers.any((u) => u.username == queryStr)) {
      _tabController.animateTo(1); // Accounts
    } else {
      _tabController.animateTo(0); // Top
    }
  }

  @override
  Widget build(BuildContext context) {
    final showTabs = _query.isNotEmpty || _focused;

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
              child: AnimatedBuilder(
                animation: widget.feedService,
                builder: (context, _) {
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
                controller: _searchController,
                focusNode: _focusNode,
                onChanged: (v) {
                  final trimmed = v.trim();
                  setState(() => _query = trimmed);
                  if (trimmed.startsWith('#') && _tabController.index != 2) {
                    _tabController.animateTo(2);
                  }
                },
                onSubmitted: (v) => _addRecentSearch(v),
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
                  suffixIcon: _query.isNotEmpty
                      ? GestureDetector(
                          onTap: _clearSearch,
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
          if (!_focused) ...[
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
              onTap: _clearSearch,
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
          return Container(
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
            decoration: BoxDecoration(
              color: isDarkTheme
                  ? const Color(0xFF262626)
                  : const Color(0xFFEFEFEF),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 14, color: context.textPrimaryColor),
                  const SizedBox(width: 4),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: context.textPrimaryColor,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Data Extractor Helpers ────────────────────────────────────────────────

  List<AppUser> get _allUsers {
    final seen = <String>{};
    final users = <AppUser>[];
    for (final post in widget.feedService.posts) {
      if (seen.add(post.author.id)) users.add(post.author);
    }
    return users;
  }

  List<String> get _allTags {
    final tagsSet = <String>{};
    for (final post in widget.feedService.posts) {
      final caption = post.caption;
      final RegExp regExp = RegExp(r'#\w+');
      final matches = regExp.allMatches(caption);
      for (final match in matches) {
        tagsSet.add(match.group(0)!);
      }
    }
    return tagsSet.toList();
  }

  List<String> get _allLocations {
    final locationsSet = <String>{};
    for (final post in widget.feedService.posts) {
      if (post.location != null && post.location!.isNotEmpty) {
        locationsSet.add(post.location!);
      }
    }
    return locationsSet.toList();
  }

  Iterable<AppUser> get _filteredUsers {
    final q = _query.toLowerCase();
    if (q.isEmpty) return _allUsers;
    return _allUsers.where(
      (u) =>
          u.username.toLowerCase().contains(q) ||
          u.fullName.toLowerCase().contains(q),
    );
  }

  Iterable<String> get _filteredTags {
    final q = _query.toLowerCase();
    final all = _allTags;
    if (q.isEmpty) return all;
    final search = q.startsWith('#') ? q : '#$q';
    return all.where((t) => t.toLowerCase().contains(search.toLowerCase()));
  }

  Iterable<String> get _filteredLocations {
    final q = _query.toLowerCase();
    final all = _allLocations;
    if (q.isEmpty) return all;
    return all.where((l) => l.toLowerCase().contains(q));
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
    if (_query.isEmpty) {
      return _buildRecentSearchesSection();
    }

    final matchedUsers = _filteredUsers.take(3).toList();
    final matchedTags = _filteredTags.take(3).toList();
    final matchedLocs = _filteredLocations.take(3).toList();

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

  List<AppUser> get _suggestedUsers {
    final list = List<AppUser>.from(_allUsers);
    list.sort((a, b) => b.followers.compareTo(a.followers));
    return list.take(3).toList();
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
    return sortedTags.take(3).toList();
  }

  List<String> get _suggestedLocations {
    final frequency = <String, int>{};
    for (final post in widget.feedService.posts) {
      if (post.location != null && post.location!.isNotEmpty) {
        final loc = post.location!;
        frequency[loc] = (frequency[loc] ?? 0) + 1;
      }
    }
    final sortedLocs = frequency.keys.toList()
      ..sort((a, b) => frequency[b]!.compareTo(frequency[a]!));
    return sortedLocs.take(3).toList();
  }

  Widget _buildRecentSearchesSection() {
    final hasRecent = _recentSearches.isNotEmpty;
    final sugUsers = _suggestedUsers;
    final sugTags = _suggestedTags;
    final sugLocs = _suggestedLocations;

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
                    setState(() {
                      _recentSearches.clear();
                    });
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
          ..._recentSearches.map((item) {
            final isTag = item.startsWith('#');
            final isLoc = !isTag && _allLocations.contains(item);
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
                  setState(() {
                    _recentSearches.remove(item);
                  });
                },
              ),
              onTap: () => _selectQuery(item),
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
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: AppColors.border,
        backgroundImage: user.avatarUrl.isNotEmpty
            ? NetworkImage(user.avatarUrl)
            : null,
        child: user.avatarUrl.isEmpty
            ? const Icon(Icons.person, color: AppColors.textSecondary, size: 18)
            : null,
      ),
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
      onTap: () => _selectQuery(user.username),
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
      onTap: () => _selectQuery(tag),
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
      onTap: () => _selectQuery(location),
    );
  }

  Widget _buildRecentUserAvatar(String username) {
    final user = _allUsers.firstWhere(
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
    return CircleAvatar(
      radius: 18,
      backgroundColor: AppColors.border,
      backgroundImage: user.avatarUrl.isNotEmpty
          ? NetworkImage(user.avatarUrl)
          : null,
      child: user.avatarUrl.isEmpty
          ? const Icon(Icons.person, color: AppColors.textSecondary, size: 18)
          : null,
    );
  }

  Widget _buildAccountsTab() {
    final matches = _filteredUsers.toList();
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
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: AppColors.border,
        backgroundImage: user.avatarUrl.isNotEmpty
            ? NetworkImage(user.avatarUrl)
            : null,
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
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
      ),
      onTap: () {
        print("user:-*\$#\$*#*\$ ${user.toJson()}");
        _addRecentSearch(user.username);
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
    final matches = _filteredTags.toList();
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
        _addRecentSearch(tag);
        _selectQuery(tag);
      },
    );
  }

  Widget _buildPlacesTab() {
    final matches = _filteredLocations.toList();
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
        _addRecentSearch(location);
        _selectQuery(location);
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
        specs.add(
          _TileSpec.cover(posts.sublist(i, (i + 4).clamp(0, posts.length))),
        );
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
            builder: (_) =>
                ReelsScreen(feedService: feedService, currentUser: post.author),
          ),
        );
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
    return MediaImage(
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
    );
  }
}
