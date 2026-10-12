import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:opensource_command_center/services/github/github_token_store.dart';

class _MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  group('GitHubTokenStore', () {
    test('propagates secure-storage write failures', () async {
      final storage = _MockFlutterSecureStorage();
      when(
        () => storage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenThrow(StateError('secure storage unavailable'));

      final tokenStore = GitHubTokenStore(storage: storage);

      await expectLater(
        tokenStore.write('sensitive-token'),
        throwsA(isA<StateError>()),
      );
      verify(
        () => storage.write(
          key: 'github_oauth_access_token',
          value: 'sensitive-token',
        ),
      ).called(1);
    });

    test('reads and clears the secure token', () async {
      final storage = _MockFlutterSecureStorage();
      String? persistedToken = 'persisted-token';

      when(() => storage.containsKey(key: any(named: 'key')))
          .thenAnswer((_) async => persistedToken != null);
      when(() => storage.read(key: any(named: 'key')))
          .thenAnswer((_) async => persistedToken);
      when(() => storage.delete(key: any(named: 'key'))).thenAnswer((_) async {
        persistedToken = null;
      });
      when(
        () => storage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((invocation) async {
        persistedToken = invocation.namedArguments[#value] as String?;
      });

      final tokenStore = GitHubTokenStore(storage: storage);

      expect(await tokenStore.hasToken(), isTrue);
      expect(await tokenStore.read(), 'persisted-token');
      await tokenStore.write('new-token');
      expect(await tokenStore.read(), 'new-token');
      await tokenStore.clear();
      expect(await tokenStore.hasToken(), isFalse);
      expect(await tokenStore.read(), isEmpty);
    });

    test('propagates secure-storage read failures', () async {
      final storage = _MockFlutterSecureStorage();
      when(() => storage.read(key: any(named: 'key')))
          .thenThrow(StateError('secure storage unavailable'));

      final tokenStore = GitHubTokenStore(storage: storage);

      await expectLater(tokenStore.read(), throwsA(isA<StateError>()));
    });
  });
}
