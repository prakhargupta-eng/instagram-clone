import 'dart:async';
import 'package:flutter/material.dart';

import '../../models/user.dart';
import '../../models/post.dart';
import '../../services/feed_service.dart';
import '../../services/api_service.dart';

class SearchViewModel extends ChangeNotifier {
  SearchViewModel({required this.feedService}) {
    _init();
  }

  final FeedService feedService;

  final TextEditingController searchController = TextEditingController();
  final FocusNode focusNode = FocusNode();

  String _query = '';
  bool _focused = false;
  Timer? _debounce;

  List<AppUser> _apiUsers = [];
  bool _isSearching = false;
  String _apiQuery = '';

  String? _selectedCategory;
  List<Post> _categoryPosts = [];
  bool _isCategoryLoading = false;
  int _categoryPage = 1;
  bool _categoryHasMore = true;
  bool _isCategoryLoadingMore = false;

  final List<String> _recentSearches = [
    '#travel',
    'sarah_j',
    'New York, NY',
    '#photography',
  ];

  String get query => _query;
  bool get isFocused => _focused;
  List<AppUser> get apiUsers => _apiUsers;
  bool get isSearching => _isSearching;
  List<String> get recentSearches => _recentSearches;
  String? get selectedCategory => _selectedCategory;
  List<Post> get categoryPosts => _categoryPosts;
  bool get isCategoryLoading => _isCategoryLoading;
  bool get isCategoryLoadingMore => _isCategoryLoadingMore;
  bool get categoryHasMore => _categoryHasMore;

  void _init() {
    focusNode.addListener(() {
      _focused = focusNode.hasFocus;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    searchController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  void clearSearch(Function(int) animateToTab) {
    searchController.clear();
    focusNode.unfocus();
    _query = '';
    _focused = false;
    _apiUsers = [];
    _isSearching = false;
    _apiQuery = '';
    notifyListeners();
    animateToTab(0);
  }

  void onQueryChanged(String v, Function(int) animateToTab) {
    final trimmed = v.trim();
    _query = trimmed;
    notifyListeners();
    
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      if (trimmed.length >= 3 || trimmed.isEmpty) {
        performApiSearch(trimmed);
      }
    });
    
    if (trimmed.startsWith('#')) {
      animateToTab(2);
    }
  }

  Future<void> performApiSearch(String query) async {
    if (query.isEmpty) {
      _apiUsers = [];
      _isSearching = false;
      _apiQuery = '';
      notifyListeners();
      return;
    }

    _isSearching = true;
    _apiQuery = query;
    notifyListeners();

    try {
      final results = await ApiService.instance.search(query);
      if (_apiQuery == query) {
        final users = results
            .where((e) => e is Map<String, dynamic> && e['type'] == 'account')
            .map((e) => AppUser.fromJson(e as Map<String, dynamic>))
            .toList();
        _apiUsers = users;
        _isSearching = false;
        notifyListeners();
      }
    } catch (_) {
      if (_apiQuery == query) {
        _isSearching = false;
        notifyListeners();
      }
    }
  }

  Future<void> selectCategory(String? category) async {
    if (_selectedCategory == category) {
      _selectedCategory = null;
      _categoryPosts = [];
      notifyListeners();
      return;
    }
    
    _selectedCategory = category;
    _isCategoryLoading = true;
    _categoryPage = 1;
    _categoryHasMore = true;
    notifyListeners();
    
    if (category != null) {
      try {
        _categoryPosts = await ApiService.instance.getExplorePostsByCategory(
          category,
          page: 1,
          limit: 20,
        );
        feedService.syncBookmarksFromPosts(_categoryPosts);
        _categoryHasMore = _categoryPosts.length >= 20;
        _categoryPage = 3; // Since we fetched 20 items (2 pages of 10)
      } catch (e) {
        _categoryPosts = [];
      }
    } else {
      _categoryPosts = [];
    }
    
    _isCategoryLoading = false;
    notifyListeners();
  }

  Future<void> loadMoreCategoryPosts() async {
    if (_selectedCategory == null || _isCategoryLoadingMore || !_categoryHasMore) {
      return;
    }

    _isCategoryLoadingMore = true;
    notifyListeners();

    try {
      final morePosts = await ApiService.instance.getExplorePostsByCategory(
        _selectedCategory!,
        page: _categoryPage,
        limit: 10,
      );
      
      if (morePosts.isEmpty) {
        _categoryHasMore = false;
      } else {
        _categoryPosts.addAll(morePosts);
        feedService.syncBookmarksFromPosts(morePosts);
        _categoryHasMore = morePosts.length >= 10;
        _categoryPage++;
      }
    } catch (e) {
      // Don't decrement page since we only incremented on success
    } finally {
      _isCategoryLoadingMore = false;
      notifyListeners();
    }
  }

  void addRecentSearch(String item) {
    final trimmed = item.trim();
    if (trimmed.isEmpty) return;
    _recentSearches.remove(trimmed);
    _recentSearches.insert(0, trimmed);
    notifyListeners();
  }
  
  void removeRecentSearch(String item) {
    _recentSearches.remove(item);
    notifyListeners();
  }

  void clearRecentSearches() {
    _recentSearches.clear();
    notifyListeners();
  }

  void selectQuery(String item, Function(int) animateToTab) {
    searchController.text = item;
    searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: item.length),
    );
    _query = item.trim();
    addRecentSearch(item);

    final queryStr = item.trim();
    if (queryStr.startsWith('#')) {
      animateToTab(2); // Tags
    } else if (allLocations.contains(queryStr)) {
      animateToTab(3); // Places
    } else if (allUsers.any((u) => u.username == queryStr)) {
      animateToTab(1); // Accounts
    } else {
      animateToTab(0); // Top
    }
  }

  // ── Data Extractor Helpers ────────────────────────────────────────────────

  List<AppUser> get allUsers {
    final seen = <String>{};
    final users = <AppUser>[];
    for (final post in feedService.posts) {
      if (seen.add(post.author.id)) users.add(post.author);
    }
    return users;
  }

  List<String> get allTags {
    final tagsSet = <String>{};
    for (final post in feedService.posts) {
      final caption = post.caption;
      final RegExp regExp = RegExp(r'#\w+');
      final matches = regExp.allMatches(caption);
      for (final match in matches) {
        tagsSet.add(match.group(0)!);
      }
    }
    return tagsSet.toList();
  }

  List<String> get allLocations {
    final locationsSet = <String>{};
    for (final post in feedService.posts) {
      if (post.location != null && post.location!.isNotEmpty) {
        locationsSet.add(post.location!);
      }
    }
    return locationsSet.toList();
  }

  Iterable<AppUser> get filteredUsers {
    if (_query.isEmpty) return allUsers;
    if (_apiQuery == _query && !_isSearching && _apiUsers.isNotEmpty) {
      return _apiUsers;
    }
    final q = _query.toLowerCase();
    return allUsers.where(
      (u) =>
          u.username.toLowerCase().contains(q) ||
          u.fullName.toLowerCase().contains(q),
    );
  }

  Iterable<String> get filteredTags {
    final q = _query.toLowerCase();
    final all = allTags;
    if (q.isEmpty) return all;
    final search = q.startsWith('#') ? q : '#$q';
    return all.where((t) => t.toLowerCase().contains(search.toLowerCase()));
  }

  Iterable<String> get filteredLocations {
    final q = _query.toLowerCase();
    final all = allLocations;
    if (q.isEmpty) return all;
    return all.where((l) => l.toLowerCase().contains(q));
  }

  List<AppUser> get suggestedUsers {
    final list = List<AppUser>.from(allUsers);
    list.sort((a, b) => b.followers.compareTo(a.followers));
    return list.take(3).toList();
  }

  List<String> get suggestedTags {
    final frequency = <String, int>{};
    for (final post in feedService.posts) {
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

  List<String> get suggestedLocations {
    final frequency = <String, int>{};
    for (final post in feedService.posts) {
      if (post.location != null && post.location!.isNotEmpty) {
        final loc = post.location!;
        frequency[loc] = (frequency[loc] ?? 0) + 1;
      }
    }
    final sortedLocs = frequency.keys.toList()
      ..sort((a, b) => frequency[b]!.compareTo(frequency[a]!));
    return sortedLocs.take(3).toList();
  }
}
