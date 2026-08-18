import 'dart:async';
import 'package:flutter/foundation.dart';

import '../models/post.dart';
import '../models/story.dart';
import '../models/user.dart';
import 'api_service.dart';
import 'local_post_store.dart';

class FeedService extends ChangeNotifier {
  final List<Post> _posts = [];
  final List<Story> _stories = [];
  final Map<String, List<String>> _follows = {};
  final Map<String, AppUser> _usersById = {};
  final Set<String> _bookmarkedPostIds = {};

  bool _isLoading = false;
  bool _loadedLocal = false;

  bool get isLoading => _isLoading;
  bool get loadedLocal => _loadedLocal;

  AppUser? userById(String id) => _usersById[id];

  final List<Post> _bookmarkedPosts = [];
  List<Post> get bookmarkedPosts => _bookmarkedPosts;

  int _bookmarksPage = 1;
  bool _bookmarksHasMore = true;
  bool get bookmarksHasMore => _bookmarksHasMore;

  bool isBookmarked(String postId) => _bookmarkedPostIds.contains(postId);

  Future<void> toggleBookmark(String postId) async {
    final wasBookmarked = _bookmarkedPostIds.contains(postId);
    // Optimistic UI update
    if (wasBookmarked) {
      _bookmarkedPostIds.remove(postId);
      _bookmarkedPosts.removeWhere((p) => p.id == postId);
    } else {
      _bookmarkedPostIds.add(postId);
      // We don't have the full Post object here to add to _bookmarkedPosts,
      // but if the user views the bookmarks tab, it will refetch.
      // Alternatively, we could fetch it if needed.
    }
    notifyListeners();

    try {
      await ApiService.instance.toggleBookmark(postId);
    } catch (e) {
      debugPrint('REST API toggleBookmark error: $e');
      // Revert if API fails
      if (wasBookmarked) {
        _bookmarkedPostIds.add(postId);
      } else {
        _bookmarkedPostIds.remove(postId);
      }
      notifyListeners();
    }
  }

  Future<void> fetchBookmarks({bool loadMore = false}) async {
    if (loadMore && !_bookmarksHasMore) return;

    try {
      final pageToLoad = loadMore ? _bookmarksPage + 1 : 1;
      final posts = await ApiService.instance.getBookmarks(
        page: pageToLoad,
        limit: 10,
      );

      if (!loadMore) {
        _bookmarkedPosts.clear();
        _bookmarkedPostIds.clear();
      }

      if (posts.isNotEmpty) {
        _bookmarkedPosts.addAll(posts);
        _bookmarkedPostIds.addAll(posts.map((p) => p.id));
        _bookmarksPage = pageToLoad;
        _bookmarksHasMore = posts.length >= 10;
      } else {
        _bookmarksHasMore = false;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('REST API fetchBookmarks error: $e');
    }
  }

  void ensureUserRegistered(AppUser user) {
    if (!_usersById.containsKey(user.id)) {
      _usersById[user.id] = user;
    }
  }

  void updateUser(AppUser user) {
    _usersById[user.id] = user;
    notifyListeners();
  }

  void mergePosts(List<Post> newPosts) {
    for (final post in newPosts) {
      final index = _posts.indexWhere((p) => p.id == post.id);
      if (index != -1) {
        _posts[index] = post;
      } else {
        _posts.add(post);
      }
    }
    syncBookmarksFromPosts(newPosts);
    notifyListeners();
  }

  void syncBookmarksFromPosts(Iterable<Post> newPosts) {
    for (final p in newPosts) {
      if (p.isBookmarked) {
        _bookmarkedPostIds.add(p.id);
      }
    }
  }

  Future<void> refreshFeed() async {
    _isLoading = true;
    notifyListeners();
    try {
      final remotePosts = await ApiService.instance.getFeedPosts();
      if (remotePosts.isNotEmpty) {
        _posts.clear();
        _posts.addAll(remotePosts);
        syncBookmarksFromPosts(remotePosts);
      }
    } catch (e) {
      debugPrint('REST API Feed fetch error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> ensureLocalPostsLoaded(AppUser currentUser) async {
    if (_loadedLocal) return;
    _loadedLocal = true;
    _isLoading = true;
    notifyListeners();
    ensureUserRegistered(currentUser);

    try {
      final remotePosts = await ApiService.instance.getFeedPosts();
      _posts.clear();
      _posts.addAll(remotePosts);
      syncBookmarksFromPosts(remotePosts);
    } catch (e) {
      debugPrint('FeedService init REST error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<Post> get posts => List.unmodifiable(_posts);
  List<Story> get stories => List.unmodifiable(_stories);

  Post? getPost(String id) {
    for (final post in _posts) {
      if (post.id == id) return post;
    }
    return null;
  }

  List<String> followingIdsOf(String userId) {
    return _follows[userId] ?? const [];
  }

  bool isFollowing(String followerId, String followeeId) =>
      followingIdsOf(followerId).contains(followeeId);

  void toggleFollow(String followerId, String followeeId) async {
    final list = List<String>.from(followingIdsOf(followerId));
    final wasFollowing = list.contains(followeeId);

    if (wasFollowing) {
      list.remove(followeeId);
    } else {
      list.insert(0, followeeId);
    }
    _follows[followerId] = list;

    final follower = _usersById[followerId];
    final followee = _usersById[followeeId];
    if (follower != null) {
      final updatedFollower = follower.copyWith(
        following: (follower.following + (wasFollowing ? -1 : 1)).clamp(
          0,
          999999,
        ),
      );
      _usersById[followerId] = updatedFollower;
    }
    if (followee != null) {
      final updatedFollowee = followee.copyWith(
        followers: (followee.followers + (wasFollowing ? -1 : 1)).clamp(
          0,
          999999,
        ),
      );
      _usersById[followeeId] = updatedFollowee;
    }
    notifyListeners();

    try {
      await ApiService.instance.toggleFollow(followeeId);
    } catch (e) {
      debugPrint('REST API toggleFollow error: $e');
    }
  }

  List<Post> followingFeed(AppUser user) {
    final followed = followingIdsOf(user.id);
    final result = _posts.where((p) => followed.contains(p.author.id)).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  List<Post> forYouFeed(AppUser user) {
    final followed = followingIdsOf(user.id);
    final followedPosts = _posts.where((p) => followed.contains(p.author.id));
    final others = _posts.where((p) => !followed.contains(p.author.id));

    final othersSorted = others.toList()
      ..sort((a, b) {
        final aLikes = a.likedBy.contains(user.id)
            ? a.likedBy.length - 1
            : a.likedBy.length;
        final bLikes = b.likedBy.contains(user.id)
            ? b.likedBy.length - 1
            : b.likedBy.length;
        return bLikes.compareTo(aLikes);
      });

    return [...followedPosts, ...othersSorted];
  }

  final Set<String> _watchedStoryIds = {};

  bool isStoryWatched(String storyId) => _watchedStoryIds.contains(storyId);

  void markStoryAsWatched(String storyId) {
    if (!_watchedStoryIds.contains(storyId)) {
      _watchedStoryIds.add(storyId);
      notifyListeners();
    }
  }

  bool hasUnwatchedStories(String userId) {
    final userStories = _stories.where((s) {
      final diff = DateTime.now().difference(s.createdAt);
      return s.user.id == userId && diff.inHours < 24;
    }).toList();
    if (userStories.isEmpty) return false;
    return userStories.any((s) => !_watchedStoryIds.contains(s.id));
  }

  List<Story> storiesFor(AppUser user) {
    final followed = followingIdsOf(user.id);
    final now = DateTime.now();

    final activeStories = _stories.where((s) {
      final diff = now.difference(s.createdAt);
      return diff.inHours < 24;
    }).toList();

    final result = activeStories.where((s) {
      return s.user.id == user.id || followed.contains(s.user.id);
    }).toList();

    final seen = <String>{};
    final uniqueResult = <Story>[];
    for (final s in result) {
      if (!seen.contains(s.user.id)) {
        seen.add(s.user.id);
        uniqueResult.add(s);
      }
    }

    return uniqueResult;
  }

  void toggleLike(String postId, String userId) async {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index != -1) {
      final post = _posts[index];
      final liked = post.likedBy.contains(userId);
      final likedBy = List<String>.of(post.likedBy);

      if (liked) {
        likedBy.remove(userId);
      } else {
        likedBy.insert(0, userId);
      }
      _posts[index] = post.copyWith(likedBy: likedBy);
      notifyListeners();
    }

    try {
      await ApiService.instance.toggleLike(postId);
    } catch (e) {
      debugPrint('REST API toggleLike error: $e');
    }
  }

  void addComment(String postId, AppUser author, String text) async {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index != -1 && text.trim().isNotEmpty) {
      final post = _posts[index];
      final comments = List<Comment>.of(post.comments);
      final newComment = Comment(
        id: 'c${DateTime.now().millisecondsSinceEpoch}',
        author: author,
        text: text.trim(),
        createdAt: DateTime.now(),
      );
      comments.add(newComment);
      _posts[index] = post.copyWith(comments: comments);
      notifyListeners();
    }

    if (text.trim().isNotEmpty) {
      try {
        await ApiService.instance.addComment(postId, text);
      } catch (e) {
        debugPrint('REST API addComment error: $e');
      }
    }
  }

  void addPost(Post post) async {
    _posts.insert(0, post);
    notifyListeners();

    try {
      final taggedUserIds = post.taggedUsers.map((u) => u.id).toList();
      await ApiService.instance.createPost(
        imageUrl: post.imageUrl,
        videoUrl: post.videoUrl,
        caption: post.caption,
        location: post.location,
        music: post.music,
        isVideo: post.isVideo,
        taggedUserIds: taggedUserIds,
      );
    } catch (e) {
      debugPrint('REST API createPost error: $e');
    }
  }

  void deletePost(String postId) {
    _posts.removeWhere((p) => p.id == postId);
    LocalPostStore.instance.delete(postId);
    notifyListeners();
  }

  void addStory(Story story) async {
    _stories.insert(0, story);
    notifyListeners();

    try {
      await ApiService.instance.createStory(
        imageUrl: story.imageUrl,
        isVideo: story.isVideo,
      );
    } catch (e) {
      debugPrint('REST API createStory error: $e');
    }
  }

  final List<PendingUpload> _pendingUploads = [];
  List<PendingUpload> get pendingUploads => List.unmodifiable(_pendingUploads);

  void startPostUpload(Post post) {
    final pending = PendingUpload(
      id: post.id,
      imageUrl: post.imageUrl,
      videoUrl: post.videoUrl,
      caption: post.caption,
      location: post.location,
      music: post.music,
      author: post.author,
      isVideo: post.isVideo,
    );
    _pendingUploads.add(pending);
    notifyListeners();

    Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (pending.progress >= 1.0) {
        timer.cancel();
        _pendingUploads.removeWhere((p) => p.id == pending.id);
        addPost(post);
      } else {
        pending.progress += 0.1;
        if (pending.progress > 1.0) {
          pending.progress = 1.0;
        }
        notifyListeners();
      }
    });
  }
}

class PendingUpload {
  final String id;
  final String imageUrl;
  final String? videoUrl;
  final String caption;
  final String? location;
  final String? music;
  final AppUser author;
  final bool isVideo;
  double progress;

  PendingUpload({
    required this.id,
    required this.imageUrl,
    this.videoUrl,
    required this.caption,
    this.location,
    this.music,
    required this.author,
    this.isVideo = false,
    this.progress = 0.0,
  });
}
