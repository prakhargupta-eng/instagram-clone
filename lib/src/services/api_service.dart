import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/post.dart';
import '../models/user.dart';
import 'api_endpoints.dart';

/// Centralized API Service to manage REST HTTP requests, Auth Tokens, Headers, Logging, and States.
class ApiService extends ChangeNotifier {
  static final ApiService instance = ApiService._internal();
  factory ApiService() => instance;
  ApiService._internal();

  static const String _tokenKey = 'auth_jwt_token';
  static const String _userKey = 'auth_user_json';

  String? _token;
  AppUser? _currentUser;
  bool _isLoading = false;

  String? get token => _token;
  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _token != null && _token!.isNotEmpty;
  bool get isLoading => _isLoading;

  /// Initialize token and user session from persistent storage on startup.
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

  /// Builds standard JSON headers, appending Bearer JWT Token if available.
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

  /// Save Auth Session to local SharedPreferences
  Future<void> _saveSession(String token, Map<String, dynamic> userJson) async {
    _token = token;
    _currentUser = AppUser.fromJson(userJson);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(userJson));
    notifyListeners();
  }

  /// Clear Auth Session (Logout)
  Future<void> logout() async {
    _token = null;
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
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

  Future<http.Response> _httpGet(String url, {bool requireAuth = true}) async {
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

  Future<http.Response> _httpPost(
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

  Future<http.Response> _httpPut(
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

  // ── 1. AUTH APIs ──────────────────────────────────────────────────────────

  /// 1.1 Register User
  /// `POST /api/v1/auth/register`
  Future<AppUser> register({
    required String username,
    required String fullName,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    try {
      final response = await _httpPost(
        ApiEndpoints.register,
        requireAuth: false,
        body: {
          'username': username,
          'fullName': fullName,
          'email': email,
          'password': password,
        },
      );

      final data = _handleResponse(response);
      final token = data['token'] as String;
      final userData = data['user'] as Map<String, dynamic>;

      await _saveSession(token, userData);
      return _currentUser!;
    } finally {
      _setLoading(false);
    }
  }

  /// 1.2 Login User
  /// `POST /api/v1/auth/login`
  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    try {
      final response = await _httpPost(
        ApiEndpoints.login,
        requireAuth: false,
        body: {'email': email, 'password': password},
      );

      final data = _handleResponse(response);
      final token = data['token'] as String;
      final userData = data['user'] as Map<String, dynamic>;

      await _saveSession(token, userData);
      return _currentUser!;
    } finally {
      _setLoading(false);
    }
  }

  /// 1.3 Delete Account
  /// `POST /api/v1/auth/delete`
  Future<void> deleteAccount() async {
    final response = await _httpPost(
      ApiEndpoints.deleteAccount,
      requireAuth: true,
    );
    _handleResponse(response);
    await logout();
  }

  // ── 2. USER & PROFILE APIs ───────────────────────────────────────────────

  /// 2.1 Get User Profile
  /// `GET /api/v1/users/profile/:userId`
  Future<AppUser> getUserProfile([String? userId]) async {
    final response = await _httpGet(
      ApiEndpoints.userProfile(userId),
      requireAuth: true,
    );

    final data = _handleResponse(response);
    return AppUser.fromJson(data);
  }

  /// 2.2 Update User Profile
  /// `PUT /api/v1/users/profile`
  Future<AppUser> updateProfile({
    String? fullName,
    String? bio,
    String? avatarUrl,
    String? username,
    bool? isPrivate,
    String? website,
    String? gender,
  }) async {
    _setLoading(true);
    try {
      final body = <String, dynamic>{};
      if (fullName != null) body['fullName'] = fullName;
      if (bio != null) body['bio'] = bio;
      if (avatarUrl != null) body['avatarUrl'] = avatarUrl;
      if (username != null) body['username'] = username;
      if (isPrivate != null) body['isPrivate'] = isPrivate;
      if (website != null) body['website'] = website;
      if (gender != null) body['gender'] = gender;

      final response = await _httpPut(
        ApiEndpoints.updateProfile,
        requireAuth: true,
        body: body,
      );

      final data = _handleResponse(response);
      final updatedUser = AppUser.fromJson(data);
      _currentUser = updatedUser;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, jsonEncode(data));
      notifyListeners();

      return updatedUser;
    } finally {
      _setLoading(false);
    }
  }

  /// 2.3 Follow / Unfollow User
  /// `POST /api/v1/users/:userId/follow`
  Future<bool> toggleFollow(String userId) async {
    final response = await _httpPost(
      ApiEndpoints.followUser(userId),
      requireAuth: true,
    );

    final data = _handleResponse(response);
    return data['following'] as bool? ?? false;
  }

  /// 2.4 Search
  /// `GET /api/v1/search?q=query`
  Future<List<dynamic>> search(String query) async {
    if (query.trim().isEmpty) return [];
    final response = await _httpGet(
      ApiEndpoints.search(query),
      requireAuth: true,
    );
    final data = _handleResponse(response);
    return data['data'] as List<dynamic>? ?? [];
  }

  // ── 3. POSTS & FEED APIs ──────────────────────────────────────────────────

  /// 3.1 Get Feed Posts
  /// `GET /api/v1/posts/feed`
  Future<List<Post>> getFeedPosts() async {
    final response = await _httpGet(ApiEndpoints.feed, requireAuth: true);

    final data = _handleResponse(response);
    final List<dynamic> jsonList = data['data'] ?? [];
    return jsonList
        .map((json) => Post.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// 3.1.2 Get User Posts
  /// `GET /api/v1/users/:userId/posts` or `GET /api/v1/users/posts`
  Future<List<Post>> getUserPosts([String? userId]) async {
    final response = await _httpGet(ApiEndpoints.userPosts(userId), requireAuth: true);

    final data = _handleResponse(response);
    final List<dynamic> jsonList = data['data'] ?? [];
    return jsonList
        .map((json) => Post.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// 3.1.5 Get Reels
  /// `GET /api/v1/reels?page=...&limit=...`
  Future<List<Post>> getReels({int page = 1, int limit = 10}) async {
    final response = await _httpGet(ApiEndpoints.reels(page: page, limit: limit), requireAuth: true);

    final data = _handleResponse(response);
    print('REELS API RESPONSE: $data');
    final List<dynamic> jsonList = data['data'] ?? [];
    return jsonList
        .map((json) => Post.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// 3.2 Get Explore Posts by Category
  /// `GET /api/v1/posts/explore?category=...&page=...&limit=...`
  Future<List<Post>> getExplorePostsByCategory(
    String category, {
    int page = 1,
    int limit = 10,
  }) async {
    final response = await _httpGet(
      ApiEndpoints.exploreCategory(category, page: page, limit: limit),
      requireAuth: true,
    );

    final data = _handleResponse(response);
    final List<dynamic> jsonList = data['data'] ?? [];
    return jsonList
        .map((json) => Post.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// 3.2 Create Post
  /// `POST /api/v1/posts`
  Future<Post> createPost({
    required String imageUrl,
    String videoUrl = '',
    required String caption,
    String? location,
    String? music,
    bool isVideo = false,
    List<String> taggedUserIds = const [],
  }) async {
    _setLoading(true);
    try {
      final response = await _httpPost(
        ApiEndpoints.createPost,
        requireAuth: true,
        body: {
          'imageUrl': imageUrl,
          'videoUrl': videoUrl,
          'caption': caption,
          'location': location,
          'music': music,
          'isVideo': isVideo,
          'taggedUserIds': taggedUserIds,
        },
      );

      final data = _handleResponse(response);
      return Post.fromJson(data);
    } finally {
      _setLoading(false);
    }
  }

  /// 3.3 Get Tagged Posts for Profile Tab 3
  /// `GET /api/v1/posts/tagged/:userId`
  Future<List<Post>> getTaggedPosts(String userId) async {
    final response = await _httpGet(
      ApiEndpoints.taggedPosts(userId),
      requireAuth: true,
    );

    final data = _handleResponse(response);
    final List<dynamic> jsonList = data['data'] ?? [];
    return jsonList.map((e) => Post.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 3.4 Get Reels Feed
  /// `GET /api/v1/posts/reels`
  Future<List<Post>> getReelsFeed() async {
    final response = await _httpGet(ApiEndpoints.reels(), requireAuth: false);
    final data = _handleResponse(response);
    print('REELS FEED API RESPONSE: $data');
    final List<dynamic> jsonList = data['data'] ?? [];
    return jsonList.map((e) => Post.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ── 4. STORY APIs ────────────────────────────────────────────────────────

  /// 4.1 Get Stories Feed
  /// `GET /api/v1/stories`
  Future<List<dynamic>> getStories() async {
    final response = await _httpGet(ApiEndpoints.stories, requireAuth: false);
    final data = _handleResponse(response);
    return data['data'] as List<dynamic>? ?? [];
  }

  /// 4.2 Create Story
  /// `POST /api/v1/stories`
  Future<dynamic> createStory({
    required String imageUrl,
    bool isVideo = false,
  }) async {
    final response = await _httpPost(
      ApiEndpoints.stories,
      requireAuth: true,
      body: {'imageUrl': imageUrl, 'isVideo': isVideo},
    );
    return _handleResponse(response);
  }

  // ── 5. LIKES & COMMENTS APIs ─────────────────────────────────────────────

  /// 5.1 Like / Unlike Post
  /// `POST /api/v1/posts/:postId/like`
  Future<bool> toggleLike(String postId) async {
    final response = await _httpPost(
      ApiEndpoints.likePost(postId),
      requireAuth: true,
    );

    final data = _handleResponse(response);
    return data['liked'] as bool? ?? false;
  }

  /// 5.2 Add Comment to Post
  /// `POST /api/v1/posts/:postId/comments`
  Future<Comment> addComment(String postId, String text) async {
    final response = await _httpPost(
      ApiEndpoints.commentPost(postId),
      requireAuth: true,
      body: {'text': text},
    );

    final data = _handleResponse(response);
    return Comment.fromJson(data);
  }

  // ── 6. BOOKMARKS APIs ──────────────────────────────────────────────────────

  /// 6.1 Toggle Bookmark
  /// `POST /api/v1/posts/:postId/bookmark`
  Future<void> toggleBookmark(String postId) async {
    final response = await _httpPost(
      ApiEndpoints.bookmarkPost(postId),
      requireAuth: true,
    );
    _handleResponse(response);
  }

  /// 6.2 Get Bookmarks
  /// `GET /api/v1/users/bookmarks?page=...&limit=...`
  Future<List<Post>> getBookmarks({int page = 1, int limit = 10}) async {
    final response = await _httpGet(
      '${ApiEndpoints.getBookmarks}?page=$page&limit=$limit',
      requireAuth: true,
    );
    final data = _handleResponse(response);
    final List<dynamic> jsonList = data['bookmarks'] ?? data['data'] ?? [];
    return jsonList.map((e) {
      final postJson = e['post'] as Map<String, dynamic>? ?? e as Map<String, dynamic>;
      return Post.fromJson(postJson);
    }).toList();
  }

  // ── RESPONSE HANDLER & UTILS ──────────────────────────────────────────────

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  dynamic _handleResponse(http.Response response) {
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
