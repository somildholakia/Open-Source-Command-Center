import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:opensource_command_center/domain/domain.dart';
import 'package:opensource_command_center/services/github/github_device_flow.dart';
import 'package:opensource_command_center/services/github/github_firebase_link.dart';
import 'package:opensource_command_center/services/github/github_provider.dart';
import 'package:opensource_command_center/services/github/github_token_store.dart';

import '../../support/in_memory_connection_store.dart';
import '../../support/secure_storage_test_helper.dart';

/// Records Firebase link/unlink calls without touching Firebase.
class FakeGitHubFirebaseLinker implements GitHubFirebaseLinker {
  int linkCalls = 0;
  int unlinkCalls = 0;
  String? lastToken;
  bool result = true;

  @override
  Future<bool> linkWithGitHubToken(String token) async {
    linkCalls++;
    lastToken = token;
    return result;
  }

  @override
  Future<bool> unlinkGitHub() async {
    unlinkCalls++;
    return result;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<http.Request> requests;

  /// A MockClient simulating the GitHub device-flow + REST + GraphQL surface.
  MockClient githubMock({
    int pollSuccessAfter = 1,
    int pollNetworkFailures = 0,
    Map<String, dynamic>? profile,
  }) {
    requests = [];
    var polls = 0;
    return MockClient((request) async {
      requests.add(request);
      final path = request.url.path;

      if (path == '/login/device/code') {
        return http.Response(
          jsonEncode({
            'device_code': 'device-1',
            'user_code': 'WDJB-MJHT',
            'verification_uri': 'https://github.com/login/device',
            'expires_in': 900,
            'interval': 1,
          }),
          200,
        );
      }
      if (path == '/login/oauth/access_token') {
        polls++;
        if (polls <= pollNetworkFailures) {
          throw http.ClientException('Simulated temporary network failure');
        }
        if (polls - pollNetworkFailures < pollSuccessAfter) {
          return http.Response(
            jsonEncode({'error': 'authorization_pending'}),
            200,
          );
        }
        return http.Response(
          jsonEncode({'access_token': 'gho_test_token'}),
          200,
        );
      }
      if (path == '/user') {
        return http.Response(
          jsonEncode(
            profile ??
                {
                  'id': 1,
                  'login': 'octocat',
                  'name': 'The Octocat',
                  'avatar_url': '',
                  'html_url': 'https://github.com/octocat',
                  'public_repos': 8,
                  'followers': 100,
                },
          ),
          200,
        );
      }
      if (path == '/user/repos') {
        return http.Response(
          jsonEncode([
            {
              'id': 1,
              'name': 'hello-world',
              'full_name': 'octocat/hello-world',
              'owner': {'login': 'octocat'},
              'html_url': 'https://github.com/octocat/hello-world',
              'stargazers_count': 3,
            },
          ]),
          200,
        );
      }
      if (path == '/users/octocat/events/public') {
        return http.Response(
          jsonEncode([
            {
              'id': 'evt-1',
              'type': 'PushEvent',
              'repo': {'name': 'octocat/hello-world'},
              'payload': {
                'ref': 'refs/heads/main',
                'size': 2,
                'commits': [
                  {'message': 'a'},
                  {'message': 'b'},
                ],
              },
              'created_at': '2026-10-01T10:00:00Z',
            },
          ]),
          200,
        );
      }
      if (path == '/graphql') {
        return http.Response(
          jsonEncode({
            'data': {
              'viewer': {
                'contributionsCollection': {
                  'contributionCalendar': {
                    'totalContributions': 7,
                    'weeks': [
                      {
                        'contributionDays': [
                          {'date': '2026-10-01', 'contributionCount': 7},
                        ],
                      },
                    ],
                  },
                },
              },
            },
          }),
          200,
        );
      }
      return http.Response('not found', 404);
    });
  }

  GitHubProvider buildProvider({
    required http.Client client,
    FakeGitHubFirebaseLinker? linker,
    InMemoryConnectionStore? store,
    GitHubTokenStore? tokenStore,
  }) {
    return GitHubProvider(
      httpClient: client,
      deviceFlowClient: GitHubDeviceFlowClient(
        client: client,
        clientId: 'test-client-id',
      ),
      tokenStore:
          tokenStore ?? GitHubTokenStore(storage: createSecureStorage()),
      firebaseLinker: linker ?? FakeGitHubFirebaseLinker(),
      connectionStoreFactory: () async => store ?? InMemoryConnectionStore(),
    );
  }

  group('connect', () {
    test('runs the device flow, stores the token, and saves a token-free '
        'connection record', () async {
      final store = InMemoryConnectionStore();
      final linker = FakeGitHubFirebaseLinker();
      final provider = buildProvider(
        client: githubMock(),
        linker: linker,
        store: store,
      );

      ConnectionPrompt? prompt;
      final result = await provider.connect(onPrompt: (p) => prompt = p);

      expect(prompt?.userCode, 'WDJB-MJHT');
      expect(result.account.username, 'octocat');
      expect(result.profile.publicRepositoryCount, 8);

      // Token is held in the (secure) token store…
      expect(await provider.isConnected(), isTrue);
      // …and never inside the persisted connection record.
      expect(store.record?.providerId, 'github');
      expect(store.record?.account?.username, 'octocat');
      expect(
        jsonEncode(store.record?.toString()).contains('gho_test_token'),
        isFalse,
      );

      // The GitHub identity is linked to the Firebase account (best effort).
      expect(linker.linkCalls, 1);
      expect(linker.lastToken, 'gho_test_token');
    });

    test('retries a transient network failure while polling authorization', () async {
      final provider = buildProvider(
        client: githubMock(pollNetworkFailures: 1),
      );

      final result = await provider.connect();

      expect(result.account.username, 'octocat');
      expect(
        requests.where((r) => r.url.path == '/login/oauth/access_token'),
        hasLength(2),
      );
      expect(await provider.isConnected(), isTrue);
    });

    test('hydrates the saved token before restored API requests', () async {
      final tokenStore = GitHubTokenStore(storage: createSecureStorage());
      final store = InMemoryConnectionStore();
      final firstProvider = buildProvider(
        client: githubMock(),
        tokenStore: tokenStore,
        store: store,
      );
      await firstProvider.connect();

      // A new provider instance has an empty in-memory token mirror. Startup's
      // isConnected check must hydrate it from secure storage.
      final restoredProvider = buildProvider(
        client: githubMock(),
        tokenStore: tokenStore,
        store: store,
      );
      expect(await restoredProvider.isConnected(), isTrue);
      await restoredProvider.fetchProfile();

      final request = requests.lastWhere((r) => r.url.path == '/user');
      expect(request.headers['Authorization'], 'Bearer gho_test_token');
    });

    test(
      'fails with a configuration message when the client id is missing',
      () async {
        final provider = GitHubProvider(
          httpClient: githubMock(),
          deviceFlowClient: GitHubDeviceFlowClient(
            client: githubMock(),
            clientId: '',
          ),
          tokenStore: GitHubTokenStore(storage: createSecureStorage()),
          firebaseLinker: FakeGitHubFirebaseLinker(),
          connectionStoreFactory: () async => InMemoryConnectionStore(),
        );

        await expectLater(
          provider.connect(),
          throwsA(
            isA<AuthenticationFailed>().having(
              (failure) => failure.detail,
              'detail',
              contains('GITHUB_OAUTH_CLIENT_ID'),
            ),
          ),
        );
        expect(await provider.isConnected(), isFalse);
      },
    );

    test(
      'does not persist a token when cancelled while a poll is in flight',
      () async {
        final pollStarted = Completer<void>();
        final pollResponse = Completer<http.Response>();
        requests = [];
        final client = MockClient((request) async {
          requests.add(request);
          if (request.url.path == '/login/device/code') {
            return http.Response(
              jsonEncode({
                'device_code': 'device-1',
                'user_code': 'WDJB-MJHT',
                'verification_uri': 'https://github.com/login/device',
                'expires_in': 900,
                'interval': 1,
              }),
              200,
            );
          }
          if (request.url.path == '/login/oauth/access_token') {
            if (!pollStarted.isCompleted) pollStarted.complete();
            return pollResponse.future;
          }
          return http.Response('not found', 404);
        });
        final tokenStore = GitHubTokenStore(storage: createSecureStorage());
        final provider = buildProvider(client: client, tokenStore: tokenStore);

        final connecting = provider.connect();
        await pollStarted.future;
        provider.cancelAuthorization();
        pollResponse.complete(
          http.Response(
            jsonEncode({'access_token': 'gho_cancelled_token'}),
            200,
          ),
        );

        await expectLater(
          connecting,
          throwsA(
            isA<AuthenticationFailed>().having(
              (failure) => failure.detail,
              'detail',
              contains('cancelled'),
            ),
          ),
        );
        expect(await provider.isConnected(), isFalse);
      },
    );

    test('clears a late token when cancelled during profile loading', () async {
      final profileStarted = Completer<void>();
      final profileResponse = Completer<http.Response>();
      requests = [];
      final client = MockClient((request) async {
        requests.add(request);
        switch (request.url.path) {
          case '/login/device/code':
            return http.Response(
              jsonEncode({
                'device_code': 'device-1',
                'user_code': 'WDJB-MJHT',
                'verification_uri': 'https://github.com/login/device',
                'expires_in': 900,
                'interval': 1,
              }),
              200,
            );
          case '/login/oauth/access_token':
            return http.Response(
              jsonEncode({'access_token': 'gho_cancelled_token'}),
              200,
            );
          case '/user':
            if (!profileStarted.isCompleted) profileStarted.complete();
            return profileResponse.future;
          default:
            return http.Response('not found', 404);
        }
      });
      final tokenStore = GitHubTokenStore(storage: createSecureStorage());
      final store = InMemoryConnectionStore();
      final linker = FakeGitHubFirebaseLinker();
      final provider = buildProvider(
        client: client,
        tokenStore: tokenStore,
        store: store,
        linker: linker,
      );

      final connecting = provider.connect();
      await profileStarted.future;
      provider.cancelAuthorization();
      profileResponse.complete(
        http.Response(
          jsonEncode({
            'id': 1,
            'login': 'octocat',
            'name': 'The Octocat',
            'avatar_url': '',
            'html_url': 'https://github.com/octocat',
            'public_repos': 8,
            'followers': 100,
          }),
          200,
        ),
      );

      await expectLater(
        connecting,
        throwsA(
          isA<AuthenticationFailed>().having(
            (failure) => failure.detail,
            'detail',
            contains('cancelled'),
          ),
        ),
      );
      expect(await provider.isConnected(), isFalse);
      expect(store.record, isNull);
      expect(linker.unlinkCalls, 1);
    });

    test('stops polling when authorization is cancelled', () async {
      final client = githubMock(pollSuccessAfter: 100);
      final provider = buildProvider(client: client);

      final future = provider.connect();
      // Let the flow reach its first poll, then cancel.
      await Future<void>.delayed(const Duration(milliseconds: 10));
      provider.cancelAuthorization();

      await expectLater(
        future,
        throwsA(
          isA<AuthenticationFailed>().having(
            (failure) => failure.detail,
            'detail',
            contains('cancelled'),
          ),
        ),
      );
    });
  });

  group('data capabilities', () {
    late GitHubProvider provider;

    setUp(() async {
      provider = buildProvider(client: githubMock());
      await provider.connect();
    });

    test('fetchProfile maps the /user response', () async {
      final profile = await provider.fetchProfile();

      expect(profile.username, 'octocat');
      expect(profile.effectiveDisplayName, 'The Octocat');
      expect(profile.followersCount, 100);
    });

    test(
      'fetchRepositories maps /user/repos and sends owner filters',
      () async {
        final repos = await provider.fetchRepositories();

        expect(repos, hasLength(1));
        expect(repos.single.fullName, 'octocat/hello-world');
        final request = requests.lastWhere((r) => r.url.path == '/user/repos');
        expect(request.url.queryParameters['type'], 'owner');
        expect(request.url.queryParameters['sort'], 'updated');
      },
    );

    test(
      'fetchActivity maps /users/{username}/events/public with the limit',
      () async {
        final activity = await provider.fetchActivity(limit: 10);

        expect(activity, hasLength(1));
        expect(activity.single.type, DeveloperActivityType.commitPushed);
        expect(activity.single.commitCount, 2);
        final request = requests.lastWhere(
          (r) => r.url.path == '/users/octocat/events/public',
        );
        expect(request.url.queryParameters['per_page'], '10');
      },
    );

    test('fetchContributions maps the GraphQL contribution calendar', () async {
      final summary = await provider.fetchContributions();

      expect(summary.total, 7);
      expect(summary.countForDate(DateTime(2026, 10, 1)), 7);
    });

    test('sends the bearer token on REST calls', () async {
      await provider.fetchProfile();

      final request = requests.lastWhere((r) => r.url.path == '/user');
      expect(request.headers['Authorization'], 'Bearer gho_test_token');
    });
  });

  group('disconnect', () {
    test('clears the token, the record, and the Firebase link', () async {
      final store = InMemoryConnectionStore();
      final linker = FakeGitHubFirebaseLinker();
      final provider = buildProvider(
        client: githubMock(),
        linker: linker,
        store: store,
      );
      await provider.connect();
      expect(await provider.isConnected(), isTrue);

      await provider.disconnect();

      expect(await provider.isConnected(), isFalse);
      expect(store.record, isNull);
      expect(linker.unlinkCalls, 1);
    });

    test('reports failure when secure credential deletion fails', () async {
      final store = InMemoryConnectionStore();
      final linker = FakeGitHubFirebaseLinker();
      final tokenStore = GitHubTokenStore(
        storage: createSecureStorage(failDelete: true),
      );
      final provider = buildProvider(
        client: githubMock(),
        linker: linker,
        store: store,
        tokenStore: tokenStore,
      );

      await provider.connect();

      await expectLater(
        provider.disconnect(),
        throwsA(isA<UnknownProviderError>()),
      );

      expect(store.record, isNotNull);
      expect(linker.unlinkCalls, 0);
      // The token remains stored, but the tombstone blocks its restoration.
      expect(await tokenStore.hasToken(), isFalse);
      expect(await provider.isConnected(), isFalse);
    });

    test('is idempotent when nothing is connected', () async {
      final provider = buildProvider(client: githubMock());

      await provider.disconnect();
      await provider.disconnect();

      expect(await provider.isConnected(), isFalse);
    });
  });
}
