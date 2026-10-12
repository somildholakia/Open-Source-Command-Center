import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:opensource_command_center/domain/domain.dart';
import 'package:opensource_command_center/services/github/github_api_client.dart';

void main() {
  late List<http.Request> captured;

  GitHubApiClient clientReturning(
    http.Response Function(http.Request request) respond, {
    String token = 'test-token',
  }) {
    captured = [];
    return GitHubApiClient(
      tokenProvider: () => token,
      client: MockClient((request) async {
        captured.add(request);
        return respond(request);
      }),
    );
  }

  group('getJson', () {
    test('sends auth and API version headers, decodes JSON', () async {
      final client = clientReturning(
        (_) => http.Response(jsonEncode({'login': 'octocat'}), 200),
      );

      final json = await client.getJson('/user');

      expect(json, {'login': 'octocat'});
      expect(captured.single.headers['Authorization'], 'Bearer test-token');
      expect(captured.single.headers['Accept'], 'application/vnd.github+json');
      expect(captured.single.headers['X-GitHub-Api-Version'], '2022-11-28');
      expect(captured.single.url.toString(), 'https://api.github.com/user');
    });

    test('omits the Authorization header when no token is available', () async {
      final client = clientReturning(
        (_) => http.Response('{}', 200),
        token: '',
      );

      await client.getJson('/user');

      expect(captured.single.headers.containsKey('Authorization'), isFalse);
    });

    test('passes query parameters', () async {
      final client = clientReturning((_) => http.Response('[]', 200));

      await client.getJson(
        '/user/repos',
        queryParameters: {'type': 'owner', 'per_page': '30'},
      );

      expect(captured.single.url.queryParameters, {
        'type': 'owner',
        'per_page': '30',
      });
    });

    test('maps 401 to AuthorizationExpired', () async {
      final client = clientReturning((_) => http.Response('bad creds', 401));

      await expectLater(
        client.getJson('/user'),
        throwsA(isA<AuthorizationExpired>()),
      );
    });

    test(
      'maps 403 with exhausted quota to RateLimited with reset time',
      () async {
        final reset = DateTime.now().add(const Duration(minutes: 30));
        final client = clientReturning(
          (_) => http.Response(
            'rate limited',
            403,
            headers: {
              'x-ratelimit-remaining': '0',
              'x-ratelimit-reset': '${reset.millisecondsSinceEpoch ~/ 1000}',
            },
          ),
        );

        await expectLater(
          client.getJson('/user'),
          throwsA(
            isA<RateLimited>().having(
              (failure) => failure.resetAt?.millisecondsSinceEpoch,
              'resetAt',
              closeTo(reset.millisecondsSinceEpoch, 1000),
            ),
          ),
        );
      },
    );

    test('maps 403 without exhausted quota to PermissionDenied', () async {
      final client = clientReturning(
        (_) => http.Response(
          'forbidden',
          403,
          headers: {'x-ratelimit-remaining': '42'},
        ),
      );

      await expectLater(
        client.getJson('/user'),
        throwsA(isA<PermissionDenied>()),
      );
    });

    test('maps 404 to ProviderNotConnected', () async {
      final client = clientReturning((_) => http.Response('not found', 404));

      await expectLater(
        client.getJson('/user'),
        throwsA(isA<ProviderNotConnected>()),
      );
    });

    test('maps 422 to PermissionDenied', () async {
      final client = clientReturning(
        (_) => http.Response('unprocessable', 422),
      );

      await expectLater(
        client.getJson('/user'),
        throwsA(isA<PermissionDenied>()),
      );
    });

    test('maps 5xx to ApiUnavailable with the status code', () async {
      final client = clientReturning((_) => http.Response('boom', 503));

      await expectLater(
        client.getJson('/user'),
        throwsA(
          isA<ApiUnavailable>().having(
            (failure) => failure.statusCode,
            'statusCode',
            503,
          ),
        ),
      );
    });

    test('maps network errors to NetworkUnavailable', () async {
      final client = GitHubApiClient(
        tokenProvider: () => 'token',
        client: MockClient(
          (_) async => throw http.ClientException('connection refused'),
        ),
      );

      await expectLater(
        client.getJson('/user'),
        throwsA(isA<NetworkUnavailable>()),
      );
    });

    test('maps unparseable 200 bodies to ApiUnavailable', () async {
      final client = clientReturning((_) => http.Response('not json', 200));

      await expectLater(
        client.getJson('/user'),
        throwsA(isA<ApiUnavailable>()),
      );
    });
  });

  group('postGraphQL', () {
    test('posts the query and returns the data field', () async {
      final client = clientReturning(
        (_) => http.Response(
          jsonEncode({
            'data': {
              'viewer': {'login': 'octocat'},
            },
          }),
          200,
        ),
      );

      final data = await client.postGraphQL('query { viewer { login } }');

      expect(data, {
        'viewer': {'login': 'octocat'},
      });
      expect(captured.single.url.toString(), 'https://api.github.com/graphql');
      expect(
        jsonDecode(captured.single.body)['query'],
        'query { viewer { login } }',
      );
    });

    test('maps a non-object GraphQL response to ApiUnavailable', () async {
      final client = clientReturning((_) => http.Response('[]', 200));

      await expectLater(
        client.postGraphQL('query { viewer { login } }'),
        throwsA(isA<ApiUnavailable>()),
      );
    });

    test('throws when GraphQL returns errors without data', () async {
      final client = clientReturning(
        (_) => http.Response(
          jsonEncode({
            'errors': [
              {'message': 'Something went wrong'},
            ],
          }),
          200,
        ),
      );

      await expectLater(
        client.postGraphQL('query { viewer { login } }'),
        throwsA(isA<UnknownProviderError>()),
      );
    });

    test('returns data when errors accompany a partial payload', () async {
      final client = clientReturning(
        (_) => http.Response(
          jsonEncode({
            'data': {'viewer': null},
            'errors': [
              {'message': 'partial'},
            ],
          }),
          200,
        ),
      );

      final data = await client.postGraphQL('query { viewer { login } }');

      expect(data, {'viewer': null});
    });

    test('maps 401 on GraphQL to AuthorizationExpired', () async {
      final client = clientReturning((_) => http.Response('bad creds', 401));

      await expectLater(
        client.postGraphQL('query { viewer { login } }'),
        throwsA(isA<AuthorizationExpired>()),
      );
    });
  });
}
