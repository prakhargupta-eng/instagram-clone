import 'package:flutter_test/flutter_test.dart';

import 'package:instagram_clone/src/data/mock_data.dart';
import 'package:instagram_clone/src/models/post.dart';
import 'package:instagram_clone/src/services/feed_service.dart';

void main() {
  test('addPost inserts at top of feed', () {
    final feed = FeedService();
    final before = feed.posts.length;
    feed.addPost(
      Post(
        id: 'new',
        author: MockDatabase.alice,
        imageUrl: 'https://picsum.photos/seed/test/600/600',
        caption: 'hello',
        createdAt: DateTime.now(),
      ),
    );
    expect(feed.posts.length, before + 1);
    expect(feed.posts.first.id, 'new');
  });

  test('toggleLike adds and removes the current user', () {
    final feed = FeedService();
    final post = feed.posts.first;
    expect(post.isLikedBy('uX'), isFalse);

    feed.toggleLike(post.id, 'uX');
    expect(feed.getPost(post.id).isLikedBy('uX'), isTrue);

    feed.toggleLike(post.id, 'uX');
    expect(feed.getPost(post.id).isLikedBy('uX'), isFalse);
  });

  test('addComment appends a comment', () {
    final feed = FeedService();
    final post = feed.posts.first;
    feed.addComment(post.id, MockDatabase.alice, 'nice!');
    final updated = feed.getPost(post.id);
    expect(updated.comments.length, post.comments.length + 1);
    expect(updated.comments.last.text, 'nice!');
  });

  test('mock data contains video posts for reels', () {
    final feed = FeedService();
    final reels = feed.posts.where((p) => p.isVideo).toList();
    expect(reels.length, greaterThan(0));
    for (final reel in reels) {
      expect(reel.videoUrl, isNotEmpty);
    }
  });

  test('followingFeed only shows posts from followed users', () {
    final feed = FeedService();
    final alice = MockDatabase.alice;
    final followed = feed.followingIdsOf(alice.id);
    expect(followed, isNotEmpty);

    final feedPosts = feed.followingFeed(alice);
    expect(feedPosts, isNotEmpty);
    for (final post in feedPosts) {
      expect(followed, contains(post.author.id));
    }
  });

  test('different users get different following feeds', () {
    final feed = FeedService();
    final aliceFeed = feed.followingFeed(MockDatabase.alice).map((p) => p.id).toSet();
    final marcoFeed = feed.followingFeed(MockDatabase.marco).map((p) => p.id).toSet();
    expect(aliceFeed, isNot(equals(marcoFeed)));
  });

  test('toggleFollow adds and removes a follow', () {
    final feed = FeedService();
    final alice = MockDatabase.alice;
    final zoe = MockDatabase.zoe;

    feed.toggleFollow(alice.id, zoe.id);
    expect(feed.isFollowing(alice.id, zoe.id), isTrue);

    feed.toggleFollow(alice.id, zoe.id);
    expect(feed.isFollowing(alice.id, zoe.id), isFalse);
  });
}
