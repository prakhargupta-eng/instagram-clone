import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:instagram_clone/src/constants.dart';
import 'package:instagram_clone/src/screens/home/home_screen.dart';
import 'package:instagram_clone/src/services/auth_service.dart';
import 'package:instagram_clone/src/services/feed_service.dart';
import 'test_helper.dart';

void main() {
  testWidgets('HomeScreen renders correctly', (tester) async {
    await setupTestHive();
    final auth = AuthService();
    final feed = FeedService();
    
    await tester.runAsync(() async {
      await auth.init();
      await auth.login('alice@example.com', 'password123');
      
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(authService: auth, feedService: feed),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
    });

    expect(find.text(AppStrings.appName), findsOneWidget);
  });
}
