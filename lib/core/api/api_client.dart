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
  String? _supplierId;
  String? _cachedBaseUrl;

  ApiClient(this._db, [http.Client? client]) : _client = client ?? http.Client();

  /// Production Render backend URL by default, with local fallback or user override
  static const String productionApiUrl = 'https://foodbill-backend.onrender.com/api/v1';

  /// Default API URL depending on host platform and build mode
  static String get defaultBaseUrl {
    // If running in production release APK, point to Render production backend
    if (const bool.fromEnvironment('dart.vm.product')) {
      return productionApiUrl;
    }
    if (kIsWeb) return 'http://127.0.0.1:3000/api/v1';
    if (Platform.isAndroid) return productionApiUrl; // Default to production Render API so physical Android phones work out-of-the-box!
    return 'http://127.0.0.1:3000/api/v1';
  }

  Future<String> getBaseUrl() async {
    if (_cachedBaseUrl != null && _cachedBaseUrl!.isNotEmpty) {
      if (!kIsWeb && Platform.isAndroid && (_cachedBaseUrl!.contains('127.0.0.1') || _cachedBaseUrl!.contains('localhost'))) {
        _cachedBaseUrl = productionApiUrl;
        unawaited(setBaseUrl(productionApiUrl));
      }
      return _cachedBaseUrl!;
    }
    final setting = await (_db.select(_db.appSettings)..where((s) => s.key.equals('server_api_url'))).getSingleOrNull();
    if (setting != null && setting.value.trim().isNotEmpty) {
      final val = setting.value.trim();
      if (!kIsWeb && Platform.isAndroid && (val.contains('127.0.0.1') || val.contains('localhost'))) {
        _cachedBaseUrl = productionApiUrl;
        await setBaseUrl(productionApiUrl);
        return _cachedBaseUrl!;
      }
      _cachedBaseUrl = val;
      return _cachedBaseUrl!;
    }
    _cachedBaseUrl = defaultBaseUrl;
    return _cachedBaseUrl!;
  }

  Future<String?> getConfiguredBaseUrl() async {
    final setting = await (_db.select(_db.appSettings)..where((s) => s.key.equals('server_api_url'))).getSingleOrNull();
    if (setting != null && setting.value.trim().isNotEmpty) {
      final val = setting.value.trim();
      if (!kIsWeb && Platform.isAndroid && (val.contains('127.0.0.1') || val.contains('localhost'))) {
        await setBaseUrl(productionApiUrl);
        return productionApiUrl;
      }
      return val;
    }
    return null;
  }

  void clearCachedBaseUrl() {
    _cachedBaseUrl = null;
  }

  Future<void> setBaseUrl(String url) async {
    final clean = url.trim().replaceAll(RegExp(r'/+$'), '');
    _cachedBaseUrl = clean;
    await _db.into(_db.appSettings).insertOnConflictUpdate(
      AppSettingsCompanion.insert(key: 'server_api_url', value: clean),
    );
  }

  /// Tests connectivity to a given server base URL by probing /health
  Future<Map<String, dynamic>> testConnection(String url) async {
    final clean = url.trim().replaceAll(RegExp(r'/+$'), '');
    if (clean.isEmpty) {
      return {'success': false, 'error': 'Server URL cannot be empty'};
    }

    final healthUrls = [
      '$clean/health',
      if (clean.endsWith('/api/v1')) clean.replaceAll('/api/v1', '/health'),
      if (!clean.endsWith('/api/v1')) '$clean/api/v1/health',
    ];

    String lastError = 'No response';
    final stopwatch = Stopwatch()..start();

    for (final testUrl in healthUrls) {
      try {
        final uri = Uri.parse(testUrl);
        final response = await _client.get(uri).timeout(const Duration(seconds: 6));
        stopwatch.stop();

        if (response.statusCode >= 200 && response.statusCode < 300) {
          try {
            final data = jsonDecode(response.body);
            return {
              'success': true,
              'latencyMs': stopwatch.elapsedMilliseconds,
              'data': data,
            };
          } catch (_) {
            return {
              'success': true,
              'latencyMs': stopwatch.elapsedMilliseconds,
            };
          }
        } else {
          lastError = 'HTTP ${response.statusCode}: ${response.reasonPhrase}';
        }
      } catch (e) {
        lastError = e.toString();
      }
    }

    return {
      'success': false,
      'error': lastError,
      'latencyMs': stopwatch.elapsedMilliseconds,
    };
  }

  Future<void> restoreSavedAuth() async {
    try {
      final tokenSetting = await (_db.select(_db.appSettings)..where((s) => s.key.equals('auth_token'))).getSingleOrNull();
      if (tokenSetting != null && tokenSetting.value.isNotEmpty) {
        _authToken = tokenSetting.value;
      }
      final bizSetting = await (_db.select(_db.appSettings)..where((s) => s.key.equals('business_id'))).getSingleOrNull();
      if (bizSetting != null && bizSetting.value.isNotEmpty) {
        _businessId = bizSetting.value;
      }
      final devSetting = await (_db.select(_db.appSettings)..where((s) => s.key.equals('device_id'))).getSingleOrNull();
      if (devSetting != null && devSetting.value.isNotEmpty) {
        _deviceId = devSetting.value;
      }
      final suppSetting = await (_db.select(_db.appSettings)..where((s) => s.key.equals('supplier_id'))).getSingleOrNull();
      if (suppSetting != null && suppSetting.value.isNotEmpty) {
        _supplierId = suppSetting.value;
      }
    } catch (_) {}
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

  void setSupplierId(String? suppId) {
    _supplierId = suppId;
  }

  String? get supplierId => _supplierId;

  Future<Map<String, String>> _headers({String? idempotencyKey}) async {
    if (_authToken == null || _authToken!.isEmpty) {
      await restoreSavedAuth();
    }
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Cache-Control': 'no-cache, no-store',
      'Pragma': 'no-cache',
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
          .timeout(const Duration(seconds: 25));
      return _handleResponse(response);
    } on SocketException catch (e) {
      throw NetworkException('Connection failed: ${e.message}');
    } on TimeoutException {
      throw NetworkException('Request timed out. Please check network connection.');
    }
  }

  Future<dynamic> post(String path, {dynamic body, String? idempotencyKey, Duration? timeout}) async {
    final base = await getBaseUrl();
    final uri = Uri.parse('$base$path');

    try {
      final response = await _client
          .post(
            uri,
            headers: await _headers(idempotencyKey: idempotencyKey),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(timeout ?? const Duration(seconds: 25));
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

  Future<dynamic> patch(String path, {dynamic body}) async {
    final base = await getBaseUrl();
    final uri = Uri.parse('$base$path');

    try {
      final response = await _client
          .patch(
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
    if (response.statusCode == 304) {
      // 304 Not Modified - return safe empty change response for sync
      return {'changes': [], 'notModified': true};
    }

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
