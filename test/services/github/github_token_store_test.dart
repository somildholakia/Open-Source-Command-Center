import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:opensource_command_center/services/github/github_token_store.dart';

import '../../support/secure_storage_test_helper.dart';

class _FailingSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  group('GitHubTokenStore', () {
    test('propagates secure-storage write failures', () async {
      final storage = _FailingSecureStorage();
      when(
        () => storage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenThrow(
        StateError('secure storage unavailable'),
      );

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
      final storage = createSecureStorage();
      final tokenStore = GitHubTokenStore(storage: storage);

      await tokenStore.write('persisted-token');
      expect(await tokenStore.hasToken(), isTrue);
      expect(await tokenStore.read(), 'persisted-token');

      await tokenStore.write('new-token');
      expect(await tokenStore.read(), 'new-token');

      await tokenStore.clear();
      expect(await tokenStore.hasToken(), isFalse);
      expect(await tokenStore.read(), isEmpty);
    });

    test('propagates secure-storage delete failures', () async {
      final storage = _FailingSecureStorage();
      when(
        () => storage.delete(key: any(named: 'key')),
      ).thenThrow(StateError('secure storage unavailable'));

      final tokenStore = GitHubTokenStore(storage: storage);

      await expectLater(tokenStore.clear(), throwsA(isA<StateError>()));
    });

    test('propagates secure-storage read failures', () async {
      final storage = _FailingSecureStorage();
      when(
        () => storage.read(key: any(named: 'key')),
      ).thenThrow(StateError('secure storage unavailable'));

      final tokenStore = GitHubTokenStore(storage: storage);

      await expectLater(tokenStore.read(), throwsA(isA<StateError>()));
    });
  });
}
