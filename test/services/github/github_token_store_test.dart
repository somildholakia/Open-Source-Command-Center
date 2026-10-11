import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:opensource_command_center/services/github/github_token_store.dart';

class _MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  group('GitHubTokenStore memory fallback', () {
    test(
      'keeps the fallback readable when secure reads later succeed without a token',
      () async {
        final storage = _MockFlutterSecureStorage();
        when(
          () => storage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          ),
        ).thenThrow(StateError('secure storage unavailable'));
        when(
          () => storage.containsKey(key: any(named: 'key')),
        ).thenAnswer((_) async => false);
        when(
          () => storage.read(key: any(named: 'key')),
        ).thenAnswer((_) async => null);

        final tokenStore = GitHubTokenStore(storage: storage);
        await tokenStore.write('memory-token');

        expect(await tokenStore.hasToken(), isTrue);
        expect(await tokenStore.read(), 'memory-token');
      },
    );

    test(
      'clears a stale fallback after a secure write succeeds',
      () async {
        final storage = _MockFlutterSecureStorage();
        var failWrites = true;
        String? persistedToken;

        when(
          () => storage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          ),
        ).thenAnswer((invocation) async {
          if (failWrites) {
            throw StateError('temporary secure storage failure');
          }
          persistedToken = invocation.namedArguments[#value] as String?;
        });
        when(
          () => storage.containsKey(key: any(named: 'key')),
        ).thenAnswer((_) async => persistedToken != null);
        when(
          () => storage.read(key: any(named: 'key')),
        ).thenAnswer((_) async => persistedToken);

        final tokenStore = GitHubTokenStore(storage: storage);
        await tokenStore.write('old-memory-token');
        failWrites = false;
        await tokenStore.write('secure-token');

        expect(await tokenStore.hasToken(), isTrue);
        expect(await tokenStore.read(), 'secure-token');

        // If the secure token is subsequently absent, the old in-memory
        // fallback must not resurrect it.
        persistedToken = null;
        expect(await tokenStore.hasToken(), isFalse);
        expect(await tokenStore.read(), isEmpty);
      },
    );
  });
}
