import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:instagram_clone/src/app.dart';

void main() {
  testWidgets('App renders login screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const InstaCloneApp());
    await tester.pumpAndSettle();
    expect(find.text('Log In'), findsOneWidget);
  });
}
