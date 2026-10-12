import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opensource_command_center/app.dart';
import 'package:opensource_command_center/services/firebase/auth_service.dart';
import 'package:opensource_command_center/services/progression/progression_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_developer_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'unconfigured Firebase startup preserves a saved GitHub connection',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final provider = FakeDeveloperProvider(
        connected: true,
        profile: sampleProfile(),
      );

      await tester.pumpWidget(
        App(
          authService: AuthService(),
          developerProvider: provider,
          progressionStore: InMemoryProgressionStore(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      expect(provider.disconnectCalls, 0);
      expect(find.text('Preview app (local demo)'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
