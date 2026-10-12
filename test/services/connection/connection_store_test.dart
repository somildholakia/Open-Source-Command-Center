import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opensource_command_center/domain/domain.dart';
import 'package:opensource_command_center/services/connection/connection_store.dart';
import 'package:opensource_command_center/services/github/github_token_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SharedPrefsConnectionStore', () {
    late SharedPreferences prefs;
    late SharedPrefsConnectionStore store;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      store = SharedPrefsConnectionStore(prefs);
    });

    test('round-trips a connection record', () async {
      final record = ProviderConnectionRecord.connected(
        providerId: 'github',
        account: const ConnectedAccount(
          providerId: 'github',
          username: 'octocat',
          avatarUrl: 'https://avatars.example/1',
          profileUrl: 'https://github.com/octocat',
          connectedAt: null,
        ),
        lastSyncedAt: DateTime(2026, 10, 1, 12),
      );

      await store.save(record);
      final loaded = store.load();

      expect(loaded?.providerId, 'github');
      expect(loaded?.account?.username, 'octocat');
      expect(loaded?.account?.avatarUrl, 'https://avatars.example/1');
      expect(loaded?.lastSyncedAt, DateTime(2026, 10, 1, 12));
    });

    test('returns null when nothing was saved', () {
      expect(store.load(), isNull);
    });

    test(
      'treats corrupt payloads as disconnected instead of crashing',
      () async {
        await prefs.setString('provider_connection_record', 'not-json{');
        expect(store.load(), isNull);
      },
    );

    test('never persists token-like material', () async {
      await store.save(
        ProviderConnectionRecord.connected(
          providerId: 'github',
          account: const ConnectedAccount(
            providerId: 'github',
            username: 'octocat',
            avatarUrl: '',
            profileUrl: '',
          ),
        ),
      );

      final raw = prefs.getString('provider_connection_record') ?? '';
      expect(raw, isNotEmpty);
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      expect(decoded.containsKey('accessToken'), isFalse);
      expect(decoded.containsKey('token'), isFalse);
      expect(raw.contains('gho_'), isFalse);
    });

    test('clear removes the record', () async {
      await store.save(const ProviderConnectionRecord(providerId: 'github'));
      expect(store.load(), isNotNull);

      await store.clear();
      expect(store.load(), isNull);
    });
  });
}
