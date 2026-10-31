import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../database/app_database.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final dynamic details;

  ApiException(this.statusCode, this.message, [this.details]);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class NetworkException implements Exception {
  final String message;
  NetworkException([this.message = 'Unable to reach backend server. Please check connection.']);

  @override
  String toString() => 'NetworkException: $message';
}

class ApiClient {
  final AppDatabase _db;
  final http.Client _client;

  String? _authToken;
  String? _businessId;
  String? _deviceId;
  String? _cachedBaseUrl;

  ApiClient(this._db, [http.Client? client]) : _client = client ?? http.Client();

  /// Default API URL depending on host platform
  static String get defaultBaseUrl {
    if (kIsWeb) return 'http://127.0.0.1:3000/api/v1';
    if (Platform.isAndroid) return 'http://10.0.2.2:3000/api/v1'; // Android emulator localhost alias
    return 'http://127.0.0.1:3000/api/v1';
  }

  Future<String> getBaseUrl() async {
    if (_cachedBaseUrl != null) return _cachedBaseUrl!;
    final setting = await (_db.select(_db.appSettings)..where((s) => s.key.equals('server_api_url'))).getSingleOrNull();
    _cachedBaseUrl = setting?.value ?? defaultBaseUrl;
    return _cachedBaseUrl!;
  }

  Future<void> setBaseUrl(String url) async {
    final clean = url.trim().replaceAll(RegExp(r'/+$'), '');
    _cachedBaseUrl = clean;
    await _db.into(_db.appSettings).insertOnConflictUpdate(
      AppSettingsCompanion.insert(key: 'server_api_url', value: clean),
    );
  }

  void setAuthToken(String? token) {
    _authToken = token;
  }

  String? get authToken => _authToken;

  void setBusinessId(String? bizId) {
    _businessId = bizId;
  }

  String? get businessId => _businessId;

  void setDeviceId(String? devId) {
    _deviceId = devId;
  }

  String? get deviceId => _deviceId;

  Future<Map<String, String>> _headers({String? idempotencyKey}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_authToken != null && _authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    if (_deviceId != null && _deviceId!.isNotEmpty) {
      headers['X-Device-Id'] = _deviceId!;
    }
    if (idempotencyKey != null && idempotencyKey.isNotEmpty) {
      headers['X-Idempotency-Key'] = idempotencyKey;
    }
    return headers;
  }

  Future<dynamic> get(String path, {Map<String, String>? queryParams}) async {
    final base = await getBaseUrl();
    var uri = Uri.parse('$base$path');
    if (queryParams != null && queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }

    try {
      final response = await _client
          .get(uri, headers: await _headers())
          .timeout(const Duration(seconds: 15));
      return _handleResponse(response);
    } on SocketException catch (e) {
      throw NetworkException('Connection failed: ${e.message}');
    } on TimeoutException {
      throw NetworkException('Request timed out after 15 seconds.');
    }
  }

  Future<dynamic> post(String path, {dynamic body, String? idempotencyKey}) async {
    final base = await getBaseUrl();
    final uri = Uri.parse('$base$path');

    try {
      final response = await _client
          .post(
            uri,
            headers: await _headers(idempotencyKey: idempotencyKey),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 25));
      return _handleResponse(response);
    } on SocketException catch (e) {
      throw NetworkException('Connection failed: ${e.message}');
    } on TimeoutException {
      throw NetworkException('Request timed out.');
    }
  }

  Future<dynamic> put(String path, {dynamic body}) async {
    final base = await getBaseUrl();
    final uri = Uri.parse('$base$path');

    try {
      final response = await _client
          .put(
            uri,
            headers: await _headers(),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 25));
      return _handleResponse(response);
    } on SocketException catch (e) {
      throw NetworkException('Connection failed: ${e.message}');
    } on TimeoutException {
      throw NetworkException('Request timed out.');
    }
  }

  Future<dynamic> delete(String path) async {
    final base = await getBaseUrl();
    final uri = Uri.parse('$base$path');

    try {
      final response = await _client
          .delete(uri, headers: await _headers())
          .timeout(const Duration(seconds: 20));
      return _handleResponse(response);
    } on SocketException catch (e) {
      throw NetworkException('Connection failed: ${e.message}');
    } on TimeoutException {
      throw NetworkException('Request timed out.');
    }
  }

  dynamic _handleResponse(http.Response response) {
    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      decoded = response.body;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
        return decoded['data'];
      }
      return decoded;
    }

    String message = 'Request failed with status ${response.statusCode}';
    if (decoded is Map<String, dynamic> && decoded['error'] != null) {
      message = decoded['error'].toString();
    }
    throw ApiException(response.statusCode, message, decoded);
  }
}
