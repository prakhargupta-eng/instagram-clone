import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:instagram_clone/src/app.dart';
import 'test_helper.dart';

void main() {
  testWidgets('App renders login screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await setupTestHive();
    
    await tester.runAsync(() async {
      await tester.pumpWidget(const InstaCloneApp());
      await Future.delayed(const Duration(milliseconds: 100));
      await tester.pump();
    });
    
    expect(find.text('Log In'), findsOneWidget);
  });
}
