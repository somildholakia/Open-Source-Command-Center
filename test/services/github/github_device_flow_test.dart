import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:opensource_command_center/domain/domain.dart';
import 'package:opensource_command_center/services/github/github_device_flow.dart';

void main() {
  late List<http.Request> captured;

  GitHubDeviceFlowClient clientReturning(
    List<http.Response> responses, {
    String clientId = 'test-client-id',
  }) {
    captured = [];
    var index = 0;
    return GitHubDeviceFlowClient(
      clientId: clientId,
      client: MockClient((request) async {
        captured.add(request);
        final response = responses[index.clamp(0, responses.length - 1)];
        index++;
        return response;
      }),
    );
  }

  http.Response deviceCodeResponse({int interval = 5, int expiresIn = 900}) {
    return http.Response(
      jsonEncode({
        'device_code': 'device-123',
        'user_code': 'WDJB-MJHT',
        'verification_uri': 'https://github.com/login/device',
        'expires_in': expiresIn,
        'interval': interval,
      }),
      200,
    );
  }

  group('start', () {
    test(
      'requests a device code with the client id and minimal scope',
      () async {
        final client = clientReturning([deviceCodeResponse()]);

        final start = await client.start();

        expect(start.userCode, 'WDJB-MJHT');
        expect(start.verificationUrl, 'https://github.com/login/device');
        expect(start.deviceCode, 'device-123');
        expect(start.intervalSeconds, 5);
        expect(
          start.expiresAt.isAfter(
            DateTime.now().add(const Duration(minutes: 10)),
          ),
          isTrue,
        );

        final body = Uri.splitQueryString(captured.single.body);
        expect(body['client_id'], 'test-client-id');
        // Minimum scope only — no repo/write scopes.
        expect(body['scope'], 'read:user');
        expect(
          captured.single.url.toString(),
          'https://github.com/login/device/code',
        );
      },
    );

    test(
      'fails with a configuration message when no client id is available',
      () async {
        final client = GitHubDeviceFlowClient(
          clientId: '',
          client: MockClient((_) async => deviceCodeResponse()),
        );

        await expectLater(
          client.start(),
          throwsA(
            isA<AuthenticationFailed>().having(
              (failure) => failure.detail,
              'detail',
              contains('GITHUB_OAUTH_CLIENT_ID'),
            ),
          ),
        );
      },
    );

    test('maps HTTP failures to typed errors', () async {
      final serverError = clientReturning([http.Response('down', 502)]);
      await expectLater(serverError.start(), throwsA(isA<ApiUnavailable>()));

      final badRequest = clientReturning([http.Response('nope', 400)]);
      await expectLater(
        badRequest.start(),
        throwsA(isA<AuthenticationFailed>()),
      );
    });

    test('surfaces GitHub error payloads', () async {
      final client = clientReturning([
        http.Response(
          jsonEncode({
            'error': 'device_flow_disabled',
            'error_description': 'Device flow is disabled for this app.',
          }),
          200,
        ),
      ]);

      await expectLater(
        client.start(),
        throwsA(
          isA<AuthenticationFailed>().having(
            (failure) => failure.detail,
            'detail',
            contains('Device flow is disabled'),
          ),
        ),
      );
    });
  });

  group('poll', () {
    DeviceFlowStart startFixture() => DeviceFlowStart(
      userCode: 'WDJB-MJHT',
      verificationUrl: 'https://github.com/login/device',
      deviceCode: 'device-123',
      intervalSeconds: 5,
      expiresAt: DateTime.now().add(const Duration(minutes: 15)),
    );

    test('returns null while authorization is pending', () async {
      final client = clientReturning([
        http.Response(jsonEncode({'error': 'authorization_pending'}), 200),
      ]);

      final token = await client.poll(start: startFixture());

      expect(token, isNull);
      final body = Uri.splitQueryString(captured.single.body);
      expect(body['device_code'], 'device-123');
      expect(
        body['grant_type'],
        'urn:ietf:params:oauth:grant-type:device_code',
      );
    });

    test('reports slow_down so the caller can widen the interval', () async {
      final client = clientReturning([
        http.Response(jsonEncode({'error': 'slow_down'}), 200),
      ]);
      var slowDowns = 0;

      final token = await client.poll(
        start: startFixture(),
        onSlowDown: () => slowDowns++,
      );

      expect(token, isNull);
      expect(slowDowns, 1);
    });

    test('returns the access token on success', () async {
      final client = clientReturning([
        http.Response(jsonEncode({'access_token': 'gho_token'}), 200),
      ]);

      final token = await client.poll(start: startFixture());

      expect(token?.accessToken, 'gho_token');
    });

    test('map expired_token to AuthenticationFailed', () async {
      final client = clientReturning([
        http.Response(jsonEncode({'error': 'expired_token'}), 200),
      ]);

      await expectLater(
        client.poll(start: startFixture()),
        throwsA(isA<AuthenticationFailed>()),
      );
    });

    test('maps access_denied to a cancellation message', () async {
      final client = clientReturning([
        http.Response(jsonEncode({'error': 'access_denied'}), 200),
      ]);

      await expectLater(
        client.poll(start: startFixture()),
        throwsA(
          isA<AuthenticationFailed>().having(
            (failure) => failure.detail,
            'detail',
            contains('cancelled'),
          ),
        ),
      );
    });

    test('maps network errors to NetworkUnavailable', () async {
      final client = GitHubDeviceFlowClient(
        clientId: 'test-client-id',
        client: MockClient((_) async => throw http.ClientException('offline')),
      );

      await expectLater(
        client.poll(start: startFixture()),
        throwsA(isA<NetworkUnavailable>()),
      );
    });
  });
}
