import 'dart:async';
import 'package:flutter/foundation.dart';

import '../data/mock_data.dart';
import '../models/post.dart';
import '../models/story.dart';
import '../models/user.dart';
import 'local_post_store.dart';
import 'sql_database_helper.dart';

class FeedService extends ChangeNotifier {
  final List<Post> _posts = [];
  final List<Story> _stories = [];
  final Map<String, List<String>> _follows = {};
  final Map<String, AppUser> _usersById = {};

  bool _loadedLocal = false;
  bool _isLoading = false;
  final Set<String> _bookmarkedPostIds = {};

  bool get isLoading => _isLoading;

  bool isBookmarked(String postId) => _bookmarkedPostIds.contains(postId);

  void toggleBookmark(String postId) {
    if (_bookmarkedPostIds.contains(postId)) {
      _bookmarkedPostIds.remove(postId);
    } else {
      _bookmarkedPostIds.add(postId);
    }
    notifyListeners();
  }

  AppUser? userById(String id) => _usersById[id];

  void ensureUserRegistered(AppUser user) {
    if (!_usersById.containsKey(user.id)) {
      _usersById[user.id] = user;
      SqlDatabaseHelper.instance.insertUser(user);
    }
  }

  Future<void> refreshFeed() async {
    _isLoading = true;
    notifyListeners();
    // Simulated API call latency (3 seconds)
    await Future.delayed(const Duration(seconds: 3));
    _isLoading = false;
    notifyListeners();
  }

  Future<void> ensureLocalPostsLoaded(AppUser currentUser) async {
    if (_loadedLocal) return;
    _loadedLocal = true;
    _isLoading = true;
    notifyListeners();
    ensureUserRegistered(currentUser);

    try {
      // Simulated API call latency for initial load (3 seconds)
      await Future.delayed(const Duration(seconds: 3));

      final db = SqlDatabaseHelper.instance;

      // Seed posts if empty
      final existingPosts = await db.getAllPosts();
      if (existingPosts.isEmpty) {
        for (final post in MockDatabase.posts) {
          await db.insertPost(post);
        }
      }

      // Seed follows if empty
      final existingFollows = await db.getAllFollows();
      if (existingFollows.isEmpty) {
        for (final entry in MockDatabase.follows.entries) {
          for (final followingId in entry.value) {
            await db.insertFollow(entry.key, followingId);
          }
        }
      }

      // Seed stories if empty
      final existingStories = await db.getAllStories();
      if (existingStories.isEmpty) {
        for (final story in MockDatabase.stories) {
          await db.insertStory(story);
        }
      }

      // Load all from SQLite
      _posts.clear();
      _posts.addAll(await db.getAllPosts());

      _stories.clear();
      _stories.addAll(await db.getAllStories());

      _watchedStoryIds.clear();
      _watchedStoryIds.addAll(await db.getWatchedStoryIds());

      _follows.clear();
      _follows.addAll(await db.getAllFollows());

      final allUsers = await db.getAllUsers();
      _usersById.clear();
      for (final user in allUsers) {
        _usersById[user.id] = user;
      }
    } catch (e) {
      debugPrint('FeedService init error: $e');
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

  List<String> followingIdsOf(String userId) => _follows[userId] ?? const [];

  bool isFollowing(String followerId, String followeeId) =>
      followingIdsOf(followerId).contains(followeeId);

  void toggleFollow(String followerId, String followeeId) {
    final list = List<String>.from(followingIdsOf(followerId));
    final wasFollowing = list.contains(followeeId);
    final db = SqlDatabaseHelper.instance;

    if (wasFollowing) {
      list.remove(followeeId);
      db.deleteFollow(followerId, followeeId);
    } else {
      list.insert(0, followeeId);
      db.insertFollow(followerId, followeeId);
    }
    _follows[followerId] = list;

    final follower = _usersById[followerId];
    final followee = _usersById[followeeId];
    if (follower != null) {
      final updatedFollower = follower.copyWith(
        following: (follower.following + (wasFollowing ? -1 : 1)).clamp(0, 999999),
      );
      _usersById[followerId] = updatedFollower;
      db.insertUser(updatedFollower);
    }
    if (followee != null) {
      final updatedFollowee = followee.copyWith(
        followers: (followee.followers + (wasFollowing ? -1 : 1)).clamp(0, 999999),
      );
      _usersById[followeeId] = updatedFollowee;
      db.insertUser(updatedFollowee);
    }
    notifyListeners();
  }

  List<Post> followingFeed(AppUser user) {
    final followed = followingIdsOf(user.id);
    final result = _posts
        .where((p) => followed.contains(p.author.id))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  List<Post> forYouFeed(AppUser user) {
    final followed = followingIdsOf(user.id);
    final followedPosts = _posts.where((p) => followed.contains(p.author.id));
    final others = _posts.where((p) => !followed.contains(p.author.id));

    final othersSorted = others.toList()
      ..sort((a, b) {
        final aLikes = a.likedBy.contains(user.id) ? a.likedBy.length - 1 : a.likedBy.length;
        final bLikes = b.likedBy.contains(user.id) ? b.likedBy.length - 1 : b.likedBy.length;
        return bLikes.compareTo(aLikes);
      });

    final result = <Post>[
      ...followedPosts.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
      ...othersSorted,
    ];
    return result;
  }

  final Set<String> _watchedStoryIds = {};

  bool isStoryWatched(String storyId) => _watchedStoryIds.contains(storyId);

  void markStoryAsWatched(String storyId) {
    if (!_watchedStoryIds.contains(storyId)) {
      _watchedStoryIds.add(storyId);
      SqlDatabaseHelper.instance.markStoryAsWatched(storyId);
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
      return s.user.id == user.id ||
          followed.contains(s.user.id);
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

  void toggleLike(String postId, String userId) {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;
    final post = _posts[index];
    final liked = post.likedBy.contains(userId);
    final likedBy = List<String>.of(post.likedBy);
    final db = SqlDatabaseHelper.instance;

    if (liked) {
      likedBy.remove(userId);
      db.removeLike(postId, userId);
    } else {
      likedBy.insert(0, userId);
      db.addLike(postId, userId);
    }
    _posts[index] = post.copyWith(likedBy: likedBy);
    notifyListeners();
  }

  void addComment(String postId, AppUser author, String text) {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index == -1 || text.trim().isEmpty) return;
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

    SqlDatabaseHelper.instance.insertComment(postId, newComment);
    notifyListeners();
  }

  void addPost(Post post) {
    _posts.insert(0, post);
    SqlDatabaseHelper.instance.insertPost(post);
    notifyListeners();
  }

  void deletePost(String postId) {
    _posts.removeWhere((p) => p.id == postId);
    LocalPostStore.instance.delete(postId);
    SqlDatabaseHelper.instance.deletePost(postId);
    notifyListeners();
  }

  void addStory(Story story) {
    _stories.insert(0, story);
    SqlDatabaseHelper.instance.insertStory(story);
    notifyListeners();
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
    required this.isVideo,
    this.progress = 0.0,
  });
}
