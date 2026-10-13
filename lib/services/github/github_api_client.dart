import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/errors/provider_failure.dart';

/// Thin GitHub API client: REST + GraphQL with auth header injection,
/// status-code mapping to typed [ProviderFailure]s, and rate-limit handling.
///
/// Maps GitHub-specific failures (401, 403 rate limit, 404, 5xx) here, inside
/// the data layer, so callers only ever deal with domain errors.
class GitHubApiClient {
  static const String _apiBaseUrl = 'https://api.github.com';
  static const String _graphqlUrl = 'https://api.github.com/graphql';
  static const Duration _defaultTimeout = Duration(seconds: 20);

  final http.Client _client;

  /// Supplies the bearer token for each request. Returning an empty string
  /// produces unauthenticated requests (callers should avoid this).
  final String Function() tokenProvider;

  GitHubApiClient({required this.tokenProvider, http.Client? client})
    : _client = client ?? http.Client();

  /// Performs an authorized GET against the GitHub REST API.
  ///
  /// Returns the decoded JSON body. Throws [ProviderFailure] subtypes.
  Future<dynamic> getJson(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    try {
      final uri = Uri.parse('$_apiBaseUrl$path')
          .replace(queryParameters: queryParameters);
      final response = await _client
          .get(uri, headers: _headers())
          .timeout(_defaultTimeout);
      return _handleResponse(response);
    } on ProviderFailure {
      rethrow;
    } on TimeoutException {
      throw NetworkUnavailable(stage: 'GitHub API request $path');
    } on http.ClientException {
      throw NetworkUnavailable(stage: 'GitHub API request $path');
    } catch (e) {
      throw UnknownProviderError(detail: e.toString());
    }
  }

  /// Performs an authorized POST against the GitHub GraphQL API (v4).
  ///
  /// Returns the `data` field of the response. Throws [ProviderFailure]s,
  /// including for GraphQL-level errors.
  Future<dynamic> postGraphQL(
    String query, {
    Map<String, dynamic>? variables,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse(_graphqlUrl),
            headers: _headers(),
            body: jsonEncode({'query': query, 'variables': ?variables}),
          )
          .timeout(_defaultTimeout);

      final decoded = _handleResponse(response);
      if (decoded is! Map<String, dynamic>) {
        throw const ApiUnavailable();
      }
      final data = decoded['data'];
      final errors = decoded['errors'];

      if (errors is List && errors.isNotEmpty && data == null) {
        throw UnknownProviderError(detail: errors.toString());
      }
      return data;
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

  Map<String, String> _headers() {
    final token = tokenProvider();
    return {
      'Accept': 'application/vnd.github+json',
      'X-GitHub-Api-Version': '2022-11-28',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  dynamic _handleResponse(http.Response response) {
    final status = response.statusCode;

    switch (status) {
      case 200:
      case 201:
        try {
          return jsonDecode(response.body);
        } catch (_) {
          throw ApiUnavailable(statusCode: status);
        }
      case 401:
        throw const AuthorizationExpired();
      case 403:
        if (response.headers['x-ratelimit-remaining'] == '0') {
          throw RateLimited(resetAt: _parseResetHeader(response));
        }
        throw const PermissionDenied();
      case 404:
        throw const ProviderNotConnected();
      case 422:
        throw const PermissionDenied();
      default:
        if (status >= 500) {
          throw ApiUnavailable(statusCode: status);
        }
        throw UnknownProviderError(detail: 'HTTP $status: ${response.body}');
    }
  }

  DateTime? _parseResetHeader(http.Response response) {
    final raw = response.headers['x-ratelimit-reset'];
    if (raw == null) return null;
    final seconds = int.tryParse(raw);
    if (seconds == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
  }

  /// Exposed for testing.
  http.Client get debugClient => _client;
}
