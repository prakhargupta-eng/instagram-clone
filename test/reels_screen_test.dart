import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_image_mock/network_image_mock.dart';

import 'package:instagram_clone/src/data/mock_data.dart';
import 'package:instagram_clone/src/screens/reels/reels_screen.dart';
import 'package:instagram_clone/src/services/feed_service.dart';
import 'test_helper.dart';

void main() {
  setUp(() async {
    await setupTestHive();
  });
  testWidgets('ReelsScreen renders video post and action rail', (tester) async {
    final feed = FeedService();
    
    await mockNetworkImagesFor(() async {
      await tester.runAsync(() async {
        await feed.ensureLocalPostsLoaded(MockDatabase.alice);
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
      });

      final reels = feed.posts.where((p) => p.isVideo).toList();
      expect(reels, isNotEmpty);
      expect(find.text(reels.first.caption), findsOneWidget);
      expect(
        find.byIcon(Icons.favorite).evaluate().isNotEmpty ||
            find.byIcon(Icons.favorite_border).evaluate().isNotEmpty,
        isTrue,
      );
    });
  });
}
