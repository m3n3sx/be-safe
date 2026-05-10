import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const baseUrl = 'https://besafe.org.pl/api/v1';
  static const Duration _timeout = Duration(seconds: 15);
  static const int _maxRetries = 3;

  String? _token;

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('jwt_token');
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  Map<String, dynamic> _decode(http.Response res) {
    if (res.statusCode >= 400 || !res.body.trimLeft().startsWith('{') && !res.body.trimLeft().startsWith('[')) {
      return {'error': 'HTTP ${res.statusCode}'};
    }
    try { return jsonDecode(res.body); } catch (_) { return {'error': 'Invalid response'}; }
  }

  /// Retry helper with exponential backoff.
  /// Retries on: timeouts, connection errors, 5xx, 429.
  /// Only applied to idempotent methods (GET) by default.
  Future<http.Response> _send(Future<http.Response> Function() sendOnce, {bool idempotent = false}) async {
    int attempt = 0;
    dynamic lastError;
    while (attempt < _maxRetries) {
      attempt++;
      try {
        final res = await sendOnce().timeout(_timeout);
        // Retry on transient server errors for idempotent requests only
        if (idempotent && (res.statusCode == 429 || (res.statusCode >= 500 && res.statusCode < 600))) {
          if (attempt < _maxRetries) {
            await _backoff(attempt);
            continue;
          }
        }
        return res;
      } on TimeoutException catch (e) {
        lastError = e;
        if (!idempotent || attempt >= _maxRetries) rethrow;
        debugPrint('[api] timeout attempt $attempt, retrying...');
      } on SocketException catch (e) {
        lastError = e;
        if (!idempotent || attempt >= _maxRetries) rethrow;
        debugPrint('[api] network error attempt $attempt: ${e.message}, retrying...');
      } on http.ClientException catch (e) {
        lastError = e;
        if (!idempotent || attempt >= _maxRetries) rethrow;
        debugPrint('[api] client error attempt $attempt: ${e.message}, retrying...');
      }
      await _backoff(attempt);
    }
    throw lastError ?? Exception('Request failed after $_maxRetries attempts');
  }

  Future<void> _backoff(int attempt) async {
    // 400ms, 800ms, 1600ms + jitter
    final base = 400 * (1 << (attempt - 1));
    final jitter = base ~/ 4;
    final delay = base + (DateTime.now().microsecondsSinceEpoch % (jitter * 2)) - jitter;
    await Future.delayed(Duration(milliseconds: delay));
  }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    try {
      final res = await _send(
        () => http.post(Uri.parse('$baseUrl$path'), headers: _headers, body: jsonEncode(body)),
        idempotent: false,
      );
      return _decode(res);
    } catch (e) {
      return {'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> get(String path, [Map<String, String>? params]) async {
    try {
      final uri = Uri.parse('$baseUrl$path').replace(queryParameters: params);
      final res = await _send(
        () => http.get(uri, headers: _headers),
        idempotent: true,
      );
      return _decode(res);
    } catch (e) {
      return {'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> patch(String path, Map<String, dynamic> body) async {
    try {
      final res = await _send(
        () => http.patch(Uri.parse('$baseUrl$path'), headers: _headers, body: jsonEncode(body)),
        idempotent: true,
      );
      return _decode(res);
    } catch (e) {
      return {'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> put(String path, Map<String, dynamic> body) async {
    try {
      final res = await _send(
        () => http.put(Uri.parse('$baseUrl$path'), headers: _headers, body: jsonEncode(body)),
        idempotent: true,
      );
      return _decode(res);
    } catch (e) {
      return {'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> delete(String path) async {
    try {
      final res = await _send(
        () => http.delete(Uri.parse('$baseUrl$path'), headers: _headers),
        idempotent: true,
      );
      return _decode(res);
    } catch (e) {
      return {'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> multipart(String path, Map<String, String> fields, {String? filePath, String fileField = 'photo'}) async {
    final req = http.MultipartRequest('POST', Uri.parse('$baseUrl$path'));
    if (_token != null) req.headers['Authorization'] = 'Bearer $_token';
    req.fields.addAll(fields);
    if (filePath != null) req.files.add(await http.MultipartFile.fromPath(fileField, filePath));
    try {
      final streamed = await req.send().timeout(const Duration(seconds: 60));
      final body = await streamed.stream.bytesToString();
      return jsonDecode(body);
    } catch (e) {
      return {'error': 'Upload error: $e'};
    }
  }

  Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }

  String? get token => _token;
}
