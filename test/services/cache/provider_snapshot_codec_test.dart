import 'package:flutter_test/flutter_test.dart';
import 'package:opensource_command_center/domain/domain.dart';
import 'package:opensource_command_center/services/cache/provider_snapshot_codec.dart';

void main() {
  group('ProviderSnapshotCodec', () {
    test('round-trips a developer profile', () {
      final value = DeveloperProfile(
        id: '123',
        username: 'octocat',
        displayName: 'The Octocat',
        avatarUrl: 'https://example.com/avatar.png',
        profileUrl: 'https://github.com/octocat',
        bio: 'Open-source enthusiast',
        publicRepositoryCount: 12,
        followersCount: 99,
        followingCount: 4,
        createdAt: DateTime.utc(2020, 1, 2),
      );

      expect(
        ProviderSnapshotCodec.decodeProfile(
          ProviderSnapshotCodec.encodeProfile(value),
        ),
        value,
      );
    });

    test('round-trips repositories and optional fields', () {
      final values = [
        Repository(
          id: '1',
          name: 'demo',
          fullName: 'octocat/demo',
          owner: 'octocat',
          url: 'https://github.com/octocat/demo',
          language: 'Dart',
          stars: 7,
          updatedAt: DateTime.utc(2026, 10, 10),
        ),
      ];

      expect(
        ProviderSnapshotCodec.decodeRepositories(
          ProviderSnapshotCodec.encodeRepositories(values),
        ),
        values,
      );
    });

    test('round-trips activity types and timestamps', () {
      final values = [
        DeveloperActivity(
          id: 'evt-1',
          type: DeveloperActivityType.commitPushed,
          repository: 'octocat/demo',
          title: 'Ship a feature',
          subtitle: '2 commits',
          identifier: 'abc123',
          rawType: 'PushEvent',
          timestamp: DateTime.utc(2026, 10, 10, 10),
          commitCount: 2,
        ),
      ];

      expect(
        ProviderSnapshotCodec.decodeActivities(
          ProviderSnapshotCodec.encodeActivities(values),
        ),
        values,
      );
    });

    test('round-trips contribution counts and fetched timestamp', () {
      final value = ContributionSummary(
        dailyCounts: const {'2026-10-09': 3, '2026-10-10': 5},
        fetchedAt: DateTime.utc(2026, 10, 10, 10),
      );

      expect(
        ProviderSnapshotCodec.decodeContributions(
          ProviderSnapshotCodec.encodeContributions(value),
        ),
        value,
      );
    });

    test('rejects activity with an unknown type', () {
      expect(
        () => ProviderSnapshotCodec.decodeActivity({
          'id': 'bad',
          'type': 'futureUnknownType',
          'timestamp': '2026-10-10T10:00:00Z',
        }),
        throwsFormatException,
      );
    });
  });
}
