import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:instagram_clone/src/screens/create/post_editor_screen.dart';
import 'test_helper.dart';

void main() {
  setUp(() async {
    await setupTestHive();
  });
  testWidgets('PostEditorScreen shows filters and toggles crop', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PostEditorScreen(
          mediaUrl: 'https://picsum.photos/seed/editor/600/600',
          isVideo: false,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Clarendon'), findsOneWidget);
    expect(find.text('Moon'), findsOneWidget);

    await tester.tap(find.text('Crop'));
    await tester.pump();

    expect(find.text('1:1'), findsOneWidget);
    expect(find.text('4:5'), findsOneWidget);

    await tester.tap(find.text('16:9'));
    await tester.pump();
    expect(find.text('16:9'), findsOneWidget);
  });
}
