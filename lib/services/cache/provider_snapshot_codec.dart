import '../../domain/domain.dart';

/// JSON codecs for the app's normalized provider entities.
///
/// These codecs intentionally exclude access tokens and raw provider payloads.
/// Keep the schema version in [LocalSnapshot] in sync with changes here.
class ProviderSnapshotCodec {
  ProviderSnapshotCodec._();

  static Map<String, dynamic> encodeProfile(DeveloperProfile value) => {
        'id': value.id,
        'username': value.username,
        'displayName': value.displayName,
        'avatarUrl': value.avatarUrl,
        'profileUrl': value.profileUrl,
        'bio': value.bio,
        'publicRepositoryCount': value.publicRepositoryCount,
        'followersCount': value.followersCount,
        'followingCount': value.followingCount,
        'createdAt': value.createdAt?.toUtc().toIso8601String(),
      };

  static DeveloperProfile decodeProfile(Map<String, dynamic> json) =>
      DeveloperProfile(
        id: _string(json['id']),
        username: _string(json['username']),
        displayName: _string(json['displayName']),
        avatarUrl: _string(json['avatarUrl']),
        profileUrl: _string(json['profileUrl']),
        bio: _string(json['bio']),
        publicRepositoryCount: _intOrNull(json['publicRepositoryCount']),
        followersCount: _intOrNull(json['followersCount']),
        followingCount: _intOrNull(json['followingCount']),
        createdAt: _dateOrNull(json['createdAt']),
      );

  static Map<String, dynamic> encodeRepository(Repository value) => {
        'id': value.id,
        'name': value.name,
        'fullName': value.fullName,
        'owner': value.owner,
        'description': value.description,
        'isPrivate': value.isPrivate,
        'isFork': value.isFork,
        'url': value.url,
        'defaultBranch': value.defaultBranch,
        'language': value.language,
        'stars': value.stars,
        'forks': value.forks,
        'openIssues': value.openIssues,
        'updatedAt': value.updatedAt?.toUtc().toIso8601String(),
      };

  static Repository decodeRepository(Map<String, dynamic> json) =>
      Repository(
        id: _string(json['id']),
        name: _string(json['name']),
        fullName: _string(json['fullName']),
        owner: _string(json['owner']),
        description: _string(json['description']),
        isPrivate: json['isPrivate'] == true,
        isFork: json['isFork'] == true,
        url: _string(json['url']),
        defaultBranch: _string(json['defaultBranch']),
        language: _string(json['language']),
        stars: _intOrNull(json['stars']),
        forks: _intOrNull(json['forks']),
        openIssues: _intOrNull(json['openIssues']),
        updatedAt: _dateOrNull(json['updatedAt']),
      );

  static Map<String, dynamic> encodeActivity(DeveloperActivity value) => {
        'id': value.id,
        'type': value.type.name,
        'repository': value.repository,
        'title': value.title,
        'subtitle': value.subtitle,
        'identifier': value.identifier,
        'rawType': value.rawType,
        'timestamp': value.timestamp.toUtc().toIso8601String(),
        'commitCount': value.commitCount,
      };

  static DeveloperActivity decodeActivity(Map<String, dynamic> json) {
    final typeName = _string(json['type']);
    final type = DeveloperActivityType.values
        .where((value) => value.name == typeName)
        .firstOrNull;
    final timestamp = _dateOrNull(json['timestamp']);
    if (type == null || timestamp == null) {
      throw const FormatException('Invalid cached developer activity.');
    }
    return DeveloperActivity(
      id: _string(json['id']),
      type: type,
      repository: _string(json['repository']),
      title: _string(json['title']),
      subtitle: json['subtitle'] as String?,
      identifier: json['identifier'] as String?,
      rawType: json['rawType'] as String?,
      timestamp: timestamp,
      commitCount: _intOrNull(json['commitCount']),
    );
  }

  static Map<String, dynamic> encodeContributions(ContributionSummary value) =>
      {
        'dailyCounts': value.dailyCounts,
        'fetchedAt': value.fetchedAt?.toUtc().toIso8601String(),
      };

  static ContributionSummary decodeContributions(Map<String, dynamic> json) {
    final rawCounts = json['dailyCounts'];
    if (rawCounts is! Map<String, dynamic>) {
      throw const FormatException('Invalid cached contribution summary.');
    }
    final counts = <String, int>{};
    for (final entry in rawCounts.entries) {
      final value = _intOrNull(entry.value);
      if (value != null && value >= 0) counts[entry.key] = value;
    }
    return ContributionSummary(
      dailyCounts: counts,
      fetchedAt: _dateOrNull(json['fetchedAt']),
    );
  }

  static List<Map<String, dynamic>> encodeRepositories(
    List<Repository> values,
  ) =>
      values.map(encodeRepository).toList(growable: false);

  static List<Repository> decodeRepositories(dynamic value) {
    if (value is! List) {
      throw const FormatException('Invalid cached repository list.');
    }
    return value
        .whereType<Map<String, dynamic>>()
        .map(decodeRepository)
        .toList(growable: false);
  }

  static List<Map<String, dynamic>> encodeActivities(
    List<DeveloperActivity> values,
  ) =>
      values.map(encodeActivity).toList(growable: false);

  static List<DeveloperActivity> decodeActivities(dynamic value) {
    if (value is! List) {
      throw const FormatException('Invalid cached activity list.');
    }
    return value
        .whereType<Map<String, dynamic>>()
        .map(decodeActivity)
        .toList(growable: false);
  }

  static String _string(dynamic value) => value is String ? value : '';

  static int? _intOrNull(dynamic value) => value is int ? value : null;

  static DateTime? _dateOrNull(dynamic value) =>
      value is String ? DateTime.tryParse(value)?.toLocal() : null;
}
