import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:opensource_command_center/domain/domain.dart';
import 'package:opensource_command_center/features/integrations/presentation/bloc/integration_bloc.dart';
import 'package:opensource_command_center/features/integrations/presentation/widgets/github_connection_card.dart';

import '../../../../support/fake_developer_provider.dart';
import '../../../../support/in_memory_connection_store.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  ProviderConnectionRecord record({String username = 'octocat'}) {
    return ProviderConnectionRecord.connected(
      providerId: 'github',
      account: ConnectedAccount(
        providerId: 'github',
        username: username,
        avatarUrl: '',
        profileUrl: '',
      ),
    );
  }

  Future<void> pumpCard(
    WidgetTester tester, {
    required FakeDeveloperProvider provider,
    InMemoryConnectionStore? store,
    Size? surfaceSize,
  }) async {
    if (surfaceSize != null) {
      tester.view.physicalSize = surfaceSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider<IntegrationBloc>(
            create: (_) {
              final bloc = IntegrationBloc(
                provider: provider,
                storeFactory: () async => store ?? InMemoryConnectionStore(),
              );
              bloc.add(const IntegrationStarted());
              return bloc;
            },
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: GithubConnectionCard(),
            ),
          ),
        ),
      ),
    );

    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
  }

  testWidgets('disconnected: shows GitHub status and a connect CTA', (
    tester,
  ) async {
    await pumpCard(tester, provider: FakeDeveloperProvider());

    expect(find.text('GitHub'), findsOneWidget);
    expect(find.text('Not connected'), findsOneWidget);
    expect(find.text('Connect GitHub'), findsOneWidget);
    expect(find.textContaining('replace sample data'), findsOneWidget);
  });

  testWidgets('connected: shows account, stats, and actions', (tester) async {
    final provider = FakeDeveloperProvider(
      connected: true,
      profile: sampleProfile(publicRepositoryCount: 12, followersCount: 340),
    );

    await pumpCard(
      tester,
      provider: provider,
      store: InMemoryConnectionStore(record()),
    );

    expect(find.text('Connected'), findsOneWidget);
    expect(find.text('@octocat'), findsOneWidget);
    expect(find.text('LIVE'), findsOneWidget);
    expect(find.textContaining('12'), findsWidgets);
    expect(find.textContaining('340'), findsWidgets);
    expect(find.text('Refresh'), findsOneWidget);
    expect(find.text('Disconnect'), findsOneWidget);
    expect(find.text('Connect GitHub'), findsNothing);
  });

  testWidgets(
    'expired: explains the revoked authorization and offers reconnect',
    (tester) async {
      final provider = FakeDeveloperProvider(
        connected: true,
        profile: sampleProfile(),
        dataFailure: const AuthorizationExpired(),
      );

      await pumpCard(
        tester,
        provider: provider,
        store: InMemoryConnectionStore(record()),
      );

      expect(find.text('Authorization expired'), findsOneWidget);
      expect(find.textContaining('expired or was revoked'), findsOneWidget);
      expect(find.text('Reconnect GitHub'), findsOneWidget);
    },
  );

  testWidgets('error: shows typed failure copy with a retry action', (
    tester,
  ) async {
    final provider = FakeDeveloperProvider(
      connectFailure: const NetworkUnavailable(),
    );

    await pumpCard(tester, provider: provider);

    // Drive a connect attempt that fails.
    await tester.tap(find.text('Connect GitHub'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }

    expect(find.text('Connection problem'), findsOneWidget);
    expect(
      find.text('No network connection. Check your internet and try again.'),
      findsOneWidget,
    );
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('connected card fits a 320dp phone without overflow', (
    tester,
  ) async {
    final provider = FakeDeveloperProvider(
      connected: true,
      profile: sampleProfile(publicRepositoryCount: 128, followersCount: 12045),
    );

    await pumpCard(
      tester,
      provider: provider,
      store: InMemoryConnectionStore(record()),
      surfaceSize: const Size(320, 640),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('@octocat'), findsOneWidget);
  });
}
