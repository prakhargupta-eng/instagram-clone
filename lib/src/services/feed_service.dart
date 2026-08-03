import 'package:flutter/foundation.dart';

import '../data/mock_data.dart';
import '../models/post.dart';
import '../models/story.dart';
import '../models/user.dart';

class FeedService extends ChangeNotifier {
  final List<Post> _posts = List.of(MockDatabase.posts);
  final List<Story> _stories = List.of(MockDatabase.stories);
  final Map<String, List<String>> _follows = {
    for (final entry in MockDatabase.follows.entries)
      entry.key: List<String>.of(entry.value),
  };

  List<Post> get posts => List.unmodifiable(_posts);
  List<Story> get stories => List.unmodifiable(_stories);

  Post getPost(String id) =>
      _posts.firstWhere((p) => p.id == id, orElse: () => _posts.first);

  List<String> followingIdsOf(String userId) => _follows[userId] ?? const [];

  bool isFollowing(String followerId, String followeeId) =>
      followingIdsOf(followerId).contains(followeeId);

  void toggleFollow(String followerId, String followeeId) {
    final list = List<String>.from(followingIdsOf(followerId));
    if (list.contains(followeeId)) {
      list.remove(followeeId);
    } else {
      list.insert(0, followeeId);
    }
    _follows[followerId] = list;
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
    final result = <Post>[
      ...followedPosts.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
      ...others.toList()..sort((a, b) => b.likes.compareTo(a.likes)),
    ];
    return result;
  }

  List<Story> storiesFor(AppUser user) {
    final followed = followingIdsOf(user.id);
    final result = _stories
        .where((s) => followed.contains(s.user.id))
        .toList()
      ..sort((a, b) => b.user.followers.compareTo(a.user.followers));
    return result;
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
    notifyListeners();
  }

  void addPost(Post post) {
    _posts.insert(0, post);
    notifyListeners();
  }

  void deletePost(String postId) {
    _posts.removeWhere((p) => p.id == postId);
    notifyListeners();
  }
}
