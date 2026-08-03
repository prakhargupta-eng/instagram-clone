import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:instagram_clone/src/screens/home/home_screen.dart';
import 'package:instagram_clone/src/services/auth_service.dart';
import 'package:instagram_clone/src/services/feed_service.dart';

void main() {
  testWidgets('HomeScreen shows For You and Following tabs', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final auth = AuthService();
    await auth.init();
    await tester.runAsync(() async {
      await auth.login('alice@example.com', 'password123');
    });
    expect(auth.isLoggedIn, isTrue);

    final feed = FeedService();
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(authService: auth, feedService: feed),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('For You'), findsOneWidget);
    expect(find.text('Following'), findsOneWidget);
  });
}
