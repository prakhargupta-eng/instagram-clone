import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../data/mock_data.dart';
import '../models/post.dart';
import '../models/story.dart';
import '../models/user.dart';
import 'local_post_store.dart';

class FeedService extends ChangeNotifier {
  final List<Post> _posts = List.of(MockDatabase.posts);
  final List<Story> _stories = List.of(MockDatabase.stories);
  final Map<String, List<String>> _follows = {
    for (final entry in MockDatabase.follows.entries)
      entry.key: List<String>.of(entry.value),
  };
  final Map<String, AppUser> _usersById = {
    for (final user in MockDatabase.users) user.id: user,
  };

  bool _loadedLocal = false;
  final Set<String> _bookmarkedPostIds = {};

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
    if (!_usersById.containsKey(user.id)) _usersById[user.id] = user;
  }

  Future<void> ensureLocalPostsLoaded(AppUser currentUser) async {
    if (_loadedLocal) return;
    _loadedLocal = true;
    ensureUserRegistered(currentUser);

    try {
      // 1. Load follows table
      final followsBox = await Hive.openBox('follows_box');
      if (followsBox.isNotEmpty) {
        _follows.clear();
        for (final key in followsBox.keys) {
          _follows[key as String] = List<String>.from(followsBox.get(key));
        }
      }

      // 2. Load posts table
      final box = await Hive.openBox('posts_box');
      final raw = box.get('all_posts_key') as String?;
      if (raw != null && raw.isNotEmpty) {
        final list = jsonDecode(raw) as List;
        _posts
          ..clear()
          ..addAll(
            list.map((e) => Post.fromJson(e as Map<String, dynamic>)).toList(),
          );

        // Merge or update default mock posts in the persisted list
        bool changedAny = false;
        for (final mockPost in MockDatabase.posts) {
          final index = _posts.indexWhere((p) => p.id == mockPost.id);
          if (index == -1) {
            _posts.add(mockPost);
            changedAny = true;
          } else {
            final existing = _posts[index];
            if (existing.videoUrl != mockPost.videoUrl || existing.imageUrl != mockPost.imageUrl) {
              _posts[index] = existing.copyWith(
                videoUrl: mockPost.videoUrl,
                imageUrl: mockPost.imageUrl,
              );
              changedAny = true;
            }
          }
        }
        if (changedAny) {
          await _persistAllPosts();
        }
      } else {
        // Save initial mock database posts
        final list = _posts.map((p) => p.toJson()).toList();
        await box.put('all_posts_key', jsonEncode(list));
      }

      // 3. Load stories
      final storiesRaw = box.get('all_stories_key') as String?;
      if (storiesRaw != null && storiesRaw.isNotEmpty) {
        final list = jsonDecode(storiesRaw) as List;
        _stories
          ..clear()
          ..addAll(
            list.map((e) => Story.fromJson(e as Map<String, dynamic>)).toList(),
          );
      } else {
        // Save initial mock stories
        final list = _stories.map((s) => s.toJson()).toList();
        await box.put('all_stories_key', jsonEncode(list));
      }
    } catch (e) {
      debugPrint('FeedService init error: $e');
    }
    notifyListeners();
  }

  Future<void> _persistAllPosts() async {
    try {
      final box = await Hive.openBox('posts_box');
      final list = _posts.map((p) => p.toJson()).toList();
      await box.put('all_posts_key', jsonEncode(list));
    } catch (_) {}
  }

  Future<void> _persistFollows() async {
    try {
      final box = await Hive.openBox('follows_box');
      for (final entry in _follows.entries) {
        await box.put(entry.key, entry.value);
      }
    } catch (_) {}
  }

  List<Post> get posts => List.unmodifiable(_posts);
  List<Story> get stories => List.unmodifiable(_stories);

  Post getPost(String id) =>
      _posts.firstWhere((p) => p.id == id, orElse: () => _posts.first);

  List<String> followingIdsOf(String userId) => _follows[userId] ?? const [];

  bool isFollowing(String followerId, String followeeId) =>
      followingIdsOf(followerId).contains(followeeId);

  void toggleFollow(String followerId, String followeeId) {
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
      _usersById[followerId] = follower.copyWith(
        following: (follower.following + (wasFollowing ? -1 : 1)).clamp(0, 999999),
      );
    }
    if (followee != null) {
      _usersById[followeeId] = followee.copyWith(
        followers: (followee.followers + (wasFollowing ? -1 : 1)).clamp(0, 999999),
      );
    }
    _persistFollows();
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

  List<Story> storiesFor(AppUser user) {
    final followed = followingIdsOf(user.id);
    final now = DateTime.now();

    // Filter stories created within the last 24 hours
    final activeStories = _stories.where((s) {
      final diff = now.difference(s.createdAt);
      return diff.inHours < 24;
    }).toList();

    // Gather eligible stories (current user, followed users, and dummy mock accounts)
    final result = activeStories.where((s) {
      return s.user.id == user.id ||
          followed.contains(s.user.id) ||
          // Include all system mock profiles so the bar is always nicely populated
          true;
    }).toList();

    // Deduplicate by user ID so each user appears once in the story bubbles list
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
    if (liked) {
      likedBy.remove(userId);
    } else {
      likedBy.insert(0, userId);
    }
    _posts[index] = post.copyWith(likedBy: likedBy);
    _persistAllPosts();
    notifyListeners();
  }

  void addComment(String postId, AppUser author, String text) {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index == -1 || text.trim().isEmpty) return;
    final post = _posts[index];
    final comments = List<Comment>.of(post.comments);
    comments.add(
      Comment(
        id: 'c${DateTime.now().millisecondsSinceEpoch}',
        author: author,
        text: text.trim(),
        createdAt: DateTime.now(),
      ),
    );
    _posts[index] = post.copyWith(comments: comments);
    _persistAllPosts();
    notifyListeners();
  }

  void addPost(Post post) {
    _posts.insert(0, post);
    _persistAllPosts();
    notifyListeners();
  }

  void deletePost(String postId) {
    _posts.removeWhere((p) => p.id == postId);
    LocalPostStore.instance.delete(postId);
    _persistAllPosts();
    notifyListeners();
  }

  Future<void> _persistStories() async {
    try {
      final box = await Hive.openBox('posts_box');
      final list = _stories.map((s) => s.toJson()).toList();
      await box.put('all_stories_key', jsonEncode(list));
    } catch (_) {}
  }

  void addStory(Story story) {
    _stories.insert(0, story);
    _persistStories();
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
