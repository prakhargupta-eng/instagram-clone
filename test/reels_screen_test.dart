import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:instagram_clone/src/data/mock_data.dart';
import 'package:instagram_clone/src/screens/reels/reels_screen.dart';
import 'package:instagram_clone/src/services/feed_service.dart';

void main() {
  testWidgets('ReelsScreen renders video post and action rail', (tester) async {
    final feed = FeedService();
    final reels = feed.posts.where((p) => p.isVideo).toList();
    expect(reels, isNotEmpty);

    await tester.pumpWidget(
      MaterialApp(
        home: ReelsScreen(
          feedService: feed,
          currentUser: MockDatabase.alice,
          initialIndex: 0,
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(find.text(reels.first.caption), findsOneWidget);
    expect(
      find.byIcon(Icons.favorite).evaluate().isNotEmpty ||
          find.byIcon(Icons.favorite_border).evaluate().isNotEmpty,
      isTrue,
    );
  });
}
