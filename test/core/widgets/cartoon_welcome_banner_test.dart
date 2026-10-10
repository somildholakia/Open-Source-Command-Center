import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opensource_command_center/core/widgets/cartoon_welcome_banner.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final width in <double>[320, 360, 430, 600]) {
    testWidgets('cartoon welcome banner fits at $width logical pixels',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 900);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              padding: EdgeInsets.all(12),
              child: CartoonWelcomeBanner(),
            ),
          ),
        ),
      );

      expect(find.text('Small commits.\nBig adventures.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
