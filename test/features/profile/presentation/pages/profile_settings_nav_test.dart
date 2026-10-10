import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:go_router/go_router.dart';
import 'package:opensource_command_center/core/theme/app_theme.dart';
import 'package:opensource_command_center/core/theme/theme_preference.dart';
import 'package:opensource_command_center/features/auth/data/models/user_model.dart';
import 'package:opensource_command_center/features/auth/presentation/bloc/auth.dart';
import 'package:opensource_command_center/features/progress/presentation/bloc/intelligence_bloc.dart';
import 'package:opensource_command_center/features/settings/presentation/pages/settings_page.dart';
import 'package:opensource_command_center/services/firebase/auth_service.dart';
import 'package:opensource_command_center/services/progression/progression_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAuthService extends Mock implements AuthService {}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ThemePreference.notifier.value = ThemeMode.dark;
  });

  group('Profile -> Settings navigation', () {
    testWidgets('tapping Settings navigates to /settings', (tester) async {
      final mockAuth = MockAuthService();
      when(
        () => mockAuth.currentUser,
      ).thenReturn(UserModel(uid: 'u', email: 'e@e.com', displayName: 'Dev'));
      final bloc = AuthBloc(authService: mockAuth);
      bloc.add(const AuthCheckRequested());

      final router = GoRouter(
        initialLocation: '/profile',
        routes: [
          GoRoute(
            path: '/profile',
            builder: (_, state) => BlocProvider.value(
              value: bloc,
              child: Material(
                child: Builder(
                  builder: (context) => Scaffold(
                    appBar: AppBar(title: const Text('Profile')),
                    body: Column(
                      children: [
                        const Expanded(child: SizedBox()),
                        ListTile(
                          leading: const Icon(Icons.settings_rounded),
                          title: const Text('Settings'),
                          subtitle: const Text('Preferences'),
                          onTap: () => GoRouter.of(context).push('/settings'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/settings',
            builder: (_, s) => MultiBlocProvider(
              providers: [
                BlocProvider.value(value: bloc),
                BlocProvider<IntelligenceBloc>(
                  create: (_) => IntelligenceBloc(InMemoryProgressionStore()),
                ),
              ],
              child: const Material(child: SettingsPage()),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(theme: AppTheme.darkTheme, routerConfig: router),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsPage), findsOneWidget);
      expect(find.text('Settings'), findsWidgets);
      bloc.close();
    });
  });
}
