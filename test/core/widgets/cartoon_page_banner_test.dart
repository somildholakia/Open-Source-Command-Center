import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opensource_command_center/core/widgets/cartoon_page_banner.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final width in <double>[320, 360, 430, 768]) {
    testWidgets('cartoon section banner fits at $width logical pixels',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 900);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: const CartoonPageBanner(
                eyebrow: 'Your developer story',
                title: 'Look how far you have grown',
                subtitle: 'Celebrate your streaks, quests and milestones.',
                icon: Icons.emoji_events_rounded,
                accent: Color(0xFF7C4DFF),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Look how far you have grown'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
