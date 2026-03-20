import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../utils/log.dart';
import 'storage_service.dart';

/// Centralised HTTP client that injects auth query params and handles
/// global error codes (401/403/500+) in a single place.
///
/// Every network call across the app should go through this client so that
/// base-URL construction, credential injection, and error logging are
/// consistent and not duplicated.
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  // ── Auth helpers ─────────────────────────────────────────────

  Future<String> _loadToken() => StorageService.loadAccessToken();

  Uri buildUri(String pathOrUrl, [Map<String, String>? extraQuery]) {
    final base = pathOrUrl.startsWith('http')
        ? pathOrUrl
        : '${AppConfig.apiBaseUrl}$pathOrUrl';
    final uri = Uri.parse(base);
    return uri.replace(queryParameters: {
      ...uri.queryParameters,
      ...?extraQuery,
    });
  }

  Uri buildAuthUri(String pathOrUrl, String token,
      [Map<String, String>? extraQuery]) {
    return buildUri(pathOrUrl, {
      ...AppConfig.authQuery(token),
      ...?extraQuery,
    });
  }

  static const _jsonHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // ── Core verbs ───────────────────────────────────────────────

  Future<http.Response> get(
    String path, {
    String? token,
    Map<String, String>? queryParams,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final t = token ?? await _loadToken();
    final uri = buildAuthUri(path, t, queryParams);
    final response = await http
        .get(uri, headers: {'Accept': 'application/json'}).timeout(timeout);
    _logIfServerError(response);
    return response;
  }

  Future<http.Response> post(
    String path, {
    String? token,
    Map<String, String>? queryParams,
    Object? body,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final t = token ?? await _loadToken();
    final uri = buildAuthUri(path, t, queryParams);
    final response = await http
        .post(uri, headers: _jsonHeaders, body: jsonEncode(body))
        .timeout(timeout);
    _logIfServerError(response);
    return response;
  }

  Future<http.Response> put(
    String path, {
    String? token,
    Map<String, String>? queryParams,
    Object? body,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final t = token ?? await _loadToken();
    final uri = buildAuthUri(path, t, queryParams);
    final response = await http
        .put(uri, headers: _jsonHeaders, body: jsonEncode(body))
        .timeout(timeout);
    _logIfServerError(response);
    return response;
  }

  Future<http.Response> delete(
    String path, {
    String? token,
    Map<String, String>? queryParams,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final t = token ?? await _loadToken();
    final uri = buildAuthUri(path, t, queryParams);
    final response = await http
        .delete(uri, headers: const {'Accept': 'application/json'})
        .timeout(timeout);
    _logIfServerError(response);
    return response;
  }

  /// Makes a GET request to any URL without injecting auth credentials.
  /// Use for third-party / external API calls (Comforta, Emsifa, etc.).
  Future<http.Response> getExternal(
    String url, {
    Map<String, String>? queryParams,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    var uri = Uri.parse(url);
    if (queryParams != null && queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: {
        ...uri.queryParameters,
        ...queryParams,
      });
    }
    final response = await http
        .get(uri, headers: const {'Accept': 'application/json'})
        .timeout(timeout);
    _logIfServerError(response);
    return response;
  }

  /// Downloads raw bytes from any URL without auth injection.
  /// Returns null on any failure so callers can degrade gracefully.
  Future<Uint8List?> downloadBytes(
    String url, {
    Duration timeout = const Duration(seconds: 15),
  }) async {
    try {
      final response =
          await http.get(Uri.parse(url)).timeout(timeout);
      if (response.statusCode == 200) return response.bodyBytes;
    } catch (e, st) {
      Log.error(e, st, reason: 'ApiClient.downloadBytes');
    }
    return null;
  }

  /// Sends a multipart POST request. Returns the streamed response
  /// converted to a regular [http.Response].
  Future<http.Response> postMultipart(
    String path, {
    String? token,
    Map<String, String> fields = const {},
    List<http.MultipartFile> files = const [],
    Duration timeout = const Duration(seconds: 60),
  }) async {
    final t = token ?? await _loadToken();
    final uri = buildAuthUri(path, t);
    final request = http.MultipartRequest('POST', uri)
      ..headers['Accept'] = 'application/json'
      ..fields.addAll(fields)
      ..files.addAll(files);

    final streamed = await request.send().timeout(timeout);
    final response = await http.Response.fromStream(streamed);
    _logIfServerError(response);
    return response;
  }

  // ── Global error logging ─────────────────────────────────────

  static const _sensitiveParams = {
    'access_token', 'client_id', 'client_secret', 'token', 'password',
  };

  /// Strips sensitive query parameters before logging to Crashlytics/console.
  static String _sanitizeUrl(Uri? url) {
    if (url == null) return '<unknown>';
    if (url.queryParameters.isEmpty) return url.toString();
    final safeParams = Map<String, String>.from(url.queryParameters)
      ..removeWhere((k, _) => _sensitiveParams.contains(k.toLowerCase()));
    return url.replace(queryParameters: safeParams.isEmpty ? null : safeParams)
        .toString();
  }

  void _logIfServerError(http.Response response) {
    final code = response.statusCode;
    final safeUrl = _sanitizeUrl(response.request?.url);

    if (code == 401 || code == 403) {
      Log.warning('Auth error $code: $safeUrl', tag: 'ApiClient');
    } else if (code >= 500) {
      Log.error(
        'Server error $code',
        StackTrace.current,
        reason: 'ApiClient $safeUrl',
      );
    }

    if (kDebugMode && code >= 400) {
      debugPrint('[ApiClient] $code $safeUrl');
    }
  }
}
