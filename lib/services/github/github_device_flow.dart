import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/errors/provider_failure.dart';
import 'github_config.dart';

/// The user-facing part of a device-flow authorization: a short code to enter
/// at the verification URL, plus the code the client polls with.
class DeviceFlowStart {
  /// Code the user types into the verification page, e.g. `WDJB-MJHT`.
  final String userCode;

  /// URL where the user enters [userCode], e.g. `https://github.com/login/device`.
  final String verificationUrl;

  /// The device code used internally for polling. Never shown to the user.
  final String deviceCode;

  /// Seconds to wait between poll attempts.
  final int intervalSeconds;

  /// When the device code expires.
  final DateTime expiresAt;

  const DeviceFlowStart({
    required this.userCode,
    required this.verificationUrl,
    required this.deviceCode,
    required this.intervalSeconds,
    required this.expiresAt,
  });
}

/// Result of a successful device-flow token exchange.
class DeviceFlowToken {
  final String accessToken;

  const DeviceFlowToken({required this.accessToken});
}

/// GitHub Device Authorization Flow client.
///
/// This is the only OAuth flow that requires **no client secret** in the
/// mobile client: the user authorizes by entering a short code in a browser,
/// and the client polls GitHub until they approve. The client id is public.
class GitHubDeviceFlowClient {
  static final Uri _deviceCodeUrl = Uri.parse(
    'https://github.com/login/device/code',
  );
  static final Uri _tokenUrl = Uri.parse(
    'https://github.com/login/oauth/access_token',
  );
  static const Duration _defaultTimeout = Duration(seconds: 20);

  final http.Client _client;

  /// OAuth app client id (public). Defaults to the build-time
  /// `GITHUB_OAUTH_CLIENT_ID`; injectable so tests can exercise the flow
  /// without a configured build.
  final String clientId;

  GitHubDeviceFlowClient({http.Client? client, String? clientId})
    : _client = client ?? http.Client(),
      clientId = clientId ?? GitHubConfig.clientId;

  /// Step 1: request a device + user code pair.
  Future<DeviceFlowStart> start() async {
    if (clientId.isEmpty) {
      throw const AuthenticationFailed(
        detail:
            'GitHub OAuth client id is not configured for this build. '
            'Provide it via --dart-define=GITHUB_OAUTH_CLIENT_ID.',
      );
    }

    try {
      final response = await _client
          .post(
            _deviceCodeUrl,
            headers: {'Accept': 'application/json'},
            body: {
              'client_id': clientId,
              'scope': GitHubConfig.scopes.join(' '),
            },
          )
          .timeout(_defaultTimeout);

      if (response.statusCode >= 500) {
        throw ApiUnavailable(statusCode: response.statusCode);
      }
      if (response.statusCode != 200) {
        throw AuthenticationFailed(
          detail: 'Device flow start failed (HTTP ${response.statusCode}).',
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const ApiUnavailable();
      }
      final body = decoded;
      final error = body['error'];
      if (error is String && error.isNotEmpty) {
        final description = body['error_description'];
        throw AuthenticationFailed(
          detail: description is String && description.isNotEmpty
              ? description
              : error,
        );
      }

      final deviceCode = body['device_code'];
      final userCode = body['user_code'];
      final verificationUri = body['verification_uri'];
      final rawInterval = body['interval'];
      final rawExpiresIn = body['expires_in'];
      final interval = rawInterval is num ? rawInterval.toInt() : 5;
      final expiresIn = rawExpiresIn is num ? rawExpiresIn.toInt() : 900;

      if (deviceCode is! String ||
          deviceCode.isEmpty ||
          userCode is! String ||
          userCode.isEmpty ||
          verificationUri is! String ||
          verificationUri.isEmpty ||
          interval < 1 ||
          expiresIn < 1) {
        throw const ApiUnavailable();
      }

      return DeviceFlowStart(
        userCode: userCode,
        verificationUrl: verificationUri,
        deviceCode: deviceCode,
        intervalSeconds: interval,
        expiresAt: DateTime.now().add(Duration(seconds: expiresIn)),
      );
    } on ProviderFailure {
      rethrow;
    } on TimeoutException {
      throw const NetworkUnavailable();
    } on http.ClientException {
      throw const NetworkUnavailable();
    } catch (e) {
      throw UnknownProviderError(detail: e.toString());
    }
  }

  /// Step 2: poll the token endpoint once.
  ///
  /// Returns null while authorization is still `pending` or `slow_down`
  /// (caller should wait and retry), or a token on success. `slow_down`
  /// bumps the interval by the documented 5 seconds via [onSlowDown].
  Future<DeviceFlowToken?> poll({
    required DeviceFlowStart start,
    void Function()? onSlowDown,
  }) async {
    try {
      final response = await _client
          .post(
            _tokenUrl,
            headers: {'Accept': 'application/json'},
            body: {
              'client_id': clientId,
              'device_code': start.deviceCode,
              'grant_type': 'urn:ietf:params:oauth:grant-type:device_code',
            },
          )
          .timeout(_defaultTimeout);

      if (response.statusCode >= 500) {
        throw ApiUnavailable(statusCode: response.statusCode);
      }
      if (response.statusCode != 200) {
        throw AuthenticationFailed(
          detail: 'Device flow poll failed (HTTP ${response.statusCode}).',
        );
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final token = body['access_token'] as String?;
      if (token != null && token.isNotEmpty) {
        return DeviceFlowToken(accessToken: token);
      }

      final error = body['error'] as String?;
      switch (error) {
        case 'authorization_pending':
          return null; // keep polling
        case 'slow_down':
          onSlowDown?.call();
          return null; // keep polling (caller widens interval)
        case 'expired_token':
          throw const AuthenticationFailed(
            detail: 'The device code expired. Please try again.',
          );
        case 'unsupported_grant_type':
        case 'incorrect_client_credentials':
        case 'incorrect_device_code':
        case 'device_flow_disabled':
          throw AuthenticationFailed(
            detail: body['error_description'] as String? ?? error,
          );
        case 'access_denied':
          throw const AuthenticationFailed(
            detail: 'Authorization was cancelled.',
          );
        default:
          if (error != null) {
            throw AuthenticationFailed(
              detail: body['error_description'] as String? ?? error,
            );
          }
          throw const ApiUnavailable();
      }
    } on ProviderFailure {
      rethrow;
    } on TimeoutException {
      throw const NetworkUnavailable();
    } on http.ClientException {
      throw const NetworkUnavailable();
    } catch (e) {
      throw UnknownProviderError(detail: e.toString());
    }
  }
}
