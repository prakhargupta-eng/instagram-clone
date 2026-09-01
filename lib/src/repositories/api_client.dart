import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import '../services/api_endpoints.dart';

/// Centralized API Client to manage REST HTTP requests, Auth Tokens, Headers, and Logging.
class ApiClient extends ChangeNotifier {
  static final ApiClient instance = ApiClient._internal();
  factory ApiClient() => instance;
  ApiClient._internal();

  static const String _tokenKey = 'auth_jwt_token';
  static const String _userKey = 'auth_user_json';

  String? _token;
  AppUser? _currentUser;
  bool _isLoading = false;

  String? get token => _token;
  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _token != null && _token!.isNotEmpty;
  bool get isLoading => _isLoading;

  Future<void> initSession() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    final userJson = prefs.getString(_userKey);
    if (userJson != null && userJson.isNotEmpty) {
      try {
        _currentUser = AppUser.fromJson(jsonDecode(userJson));
      } catch (_) {}
    }
    notifyListeners();
  }

  Map<String, String> _buildHeaders({bool requireAuth = true}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (requireAuth && _token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  Future<void> saveSession(String token, Map<String, dynamic> userJson) async {
    _token = token;
    _currentUser = AppUser.fromJson(userJson);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(userJson));
    notifyListeners();
  }

  void updateCurrentUser(AppUser user) {
    _currentUser = user;
    notifyListeners();
  }

  Future<void> updateStoredUser(Map<String, dynamic> userJson) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(userJson));
  }

  Future<void> logout() async {
    _token = null;
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // ── LOGGING HELPERS ─────────────────────────────────────────────────────────

  void _logRequest(
    String method,
    String url, {
    Map<String, String>? headers,
    dynamic body,
  }) {
    debugPrint('--------------------------------------------------');
    debugPrint('🌐 [API REQUEST] $method -> $url');
    debugPrint('📌 Base URL: ${ApiEndpoints.baseUrl}');
    if (headers != null) debugPrint('🔑 Headers: $headers');
    if (body != null) debugPrint('📦 Body: $body');
  }

  void _logResponse(http.Response response) {
    debugPrint('--------------------------------------------------');
    debugPrint(
      '✅ [API RESPONSE] Status Code: ${response.statusCode} | URL: ${response.request?.url}',
    );
    debugPrint('📄 Response Body: ${response.body}');
    debugPrint('--------------------------------------------------');
  }

  void _logError(String url, int statusCode, String error) {
    debugPrint('--------------------------------------------------');
    debugPrint('❌ [API ERROR] Status Code: $statusCode | URL: $url');
    debugPrint('📌 Base URL: ${ApiEndpoints.baseUrl}');
    debugPrint('🚨 Error Message: $error');
    debugPrint('--------------------------------------------------');
  }

  // ── HTTP CLIENT WRAPPERS ──────────────────────────────────────────────────

  Future<http.Response> getRequest(String url, {bool requireAuth = true}) async {
    final headers = _buildHeaders(requireAuth: requireAuth);
    _logRequest('GET', url, headers: headers);
    try {
      final response = await http.get(Uri.parse(url), headers: headers);
      return response;
    } catch (e) {
      _logError(url, 0, e.toString());
      rethrow;
    }
  }

  Future<http.Response> postRequest(
    String url, {
    dynamic body,
    bool requireAuth = true,
  }) async {
    final headers = _buildHeaders(requireAuth: requireAuth);
    _logRequest(
      'POST',
      url,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
      return response;
    } catch (e) {
      _logError(url, 0, e.toString());
      rethrow;
    }
  }

  Future<http.Response> putRequest(
    String url, {
    dynamic body,
    bool requireAuth = true,
  }) async {
    final headers = _buildHeaders(requireAuth: requireAuth);
    _logRequest(
      'PUT',
      url,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    try {
      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
      return response;
    } catch (e) {
      _logError(url, 0, e.toString());
      rethrow;
    }
  }

  dynamic handleResponse(http.Response response) {
    final url = response.request?.url.toString() ?? '';
    final statusCode = response.statusCode;

    _logResponse(response);

    dynamic body;
    try {
      body = jsonDecode(response.body);
    } catch (_) {
      body = response.body;
    }

    if (statusCode >= 200 && statusCode < 300) {
      return body;
    } else {
      if (statusCode == 401) {
        logout();
      }
      final errorMessage = (body is Map && body.containsKey('error'))
          ? body['error']
          : 'Server Error ($statusCode)';
      _logError(url, statusCode, errorMessage.toString());
      throw ApiException(errorMessage.toString(), statusCode: statusCode);
    }
  }
}

/// Custom Exception class for Server API Errors.
class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, {required this.statusCode});

  @override
  String toString() => message;
}
