import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:opensource_command_center/services/cache/local_snapshot_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalSnapshotStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = LocalSnapshotStore(await SharedPreferences.getInstance());
  });

  group('LocalSnapshotStore', () {
    test('round-trips a snapshot with its timestamp and schema', () async {
      final timestamp = DateTime.utc(2026, 10, 10, 12);
      await store.write(
        accountId: 'github:somil',
        namespace: 'repositories',
        payload: {
          'items': [
            {'name': 'command-center', 'stars': 3}
          ]
        },
        schemaVersion: 1,
        cachedAt: timestamp,
      );

      final snapshot = await store.read(
        accountId: 'github:somil',
        namespace: 'repositories',
        schemaVersion: 1,
      );

      expect(snapshot, isNotNull);
      expect(snapshot!.payload['items'], isA<List<dynamic>>());
      expect(snapshot.cachedAt.toUtc(), timestamp);
      expect(snapshot.schemaVersion, 1);
    });

    test('isolates snapshots by account and namespace', () async {
      await store.write(
        accountId: 'github:alice',
        namespace: 'activity',
        payload: {'count': 5},
        schemaVersion: 1,
      );

      expect(
        await store.read(
          accountId: 'github:bob',
          namespace: 'activity',
          schemaVersion: 1,
        ),
        isNull,
      );
      expect(
        await store.read(
          accountId: 'github:alice',
          namespace: 'repositories',
          schemaVersion: 1,
        ),
        isNull,
      );
    });

    test('rejects and removes snapshots from an old schema', () async {
      await store.write(
        accountId: 'github:alice',
        namespace: 'activity',
        payload: {'count': 5},
        schemaVersion: 1,
      );

      expect(
        await store.read(
          accountId: 'github:alice',
          namespace: 'activity',
          schemaVersion: 2,
        ),
        isNull,
      );
      expect(
        (await SharedPreferences.getInstance())
            .getKeys()
            .where((key) => key.startsWith('local_snapshot_v1:')),
        isEmpty,
      );
    });

    test('marks stale snapshots without deleting them', () async {
      final old = LocalSnapshot(
        payload: const {'count': 1},
        cachedAt: DateTime(2020),
        schemaVersion: 1,
      );

      expect(
        old.isStale(maxAge: const Duration(hours: 1), now: DateTime(2026)),
        isTrue,
      );
      expect(old.payload['count'], 1);
    });

    test('clears only the requested account', () async {
      await store.write(
        accountId: 'github:alice',
        namespace: 'activity',
        payload: {'count': 1},
        schemaVersion: 1,
      );
      await store.write(
        accountId: 'github:alice',
        namespace: 'repositories',
        payload: {'count': 2},
        schemaVersion: 1,
      );
      await store.write(
        accountId: 'github:bob',
        namespace: 'activity',
        payload: {'count': 3},
        schemaVersion: 1,
      );

      await store.clearAccount('github:alice');

      expect(
        await store.read(
          accountId: 'github:alice',
          namespace: 'activity',
          schemaVersion: 1,
        ),
        isNull,
      );
      expect(
        await store.read(
          accountId: 'github:bob',
          namespace: 'activity',
          schemaVersion: 1,
        ),
        isNotNull,
      );
    });
  });
}
