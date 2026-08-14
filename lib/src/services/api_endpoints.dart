import 'dart:io';

/// API Environment options
enum ApiEnvironment { server, local }

class ApiEndpoints {
  /// Active environment key (e.g. ApiEnvironment.server or ApiEnvironment.local)
  static ApiEnvironment environment = ApiEnvironment.server;

  /// Conveniences for setting environment via ApiEndpoints.prod or ApiEndpoints.loc
  static ApiEnvironment get prod => ApiEnvironment.server;
  static ApiEnvironment get loc => ApiEnvironment.local;

  /// Render Production Server Base URL
  static const String serverBaseUrl =
      'https://instagram-0q68.onrender.com/api/v1';
  static int port = 3000;
  static String customHostIp = '';

  /// Computes base URL dynamically based on current ApiEnvironment
  static String get baseUrl {
    return switch (environment) {
      ApiEnvironment.server => serverBaseUrl,
      ApiEnvironment.local =>
        customHostIp.isNotEmpty
            ? 'http://$customHostIp:$port/api/v1'
            : Platform.isAndroid
            ? 'http://10.0.2.2:$port/api/v1'
            : 'http://localhost:$port/api/v1',
    };
  }

  // 1. Auth Endpoints
  static String get register => '$baseUrl/auth/register';
  static String get login => '$baseUrl/auth/login';
  static String get refresh => '$baseUrl/auth/refresh';
  static String get deleteAccount => '$baseUrl/auth/delete';

  // 2. User & Profile Endpoints
  static String userProfile(String userId) => '$baseUrl/users/profile/$userId';
  static String get updateProfile => '$baseUrl/users/profile';
  static String followUser(String userId) => '$baseUrl/users/$userId/follow';
  static String search(String query) =>
      '$baseUrl/search?q=${Uri.encodeComponent(query)}';

  // 3. Post & Feed Endpoints
  static String get feed => '$baseUrl/posts/feed';
  static String get reels => '$baseUrl/posts/reels';
  static String exploreCategory(String category, {int page = 1, int limit = 10}) =>
      '$baseUrl/posts/explore?category=${Uri.encodeComponent(category)}&page=$page&limit=$limit';
  static String get createPost => '$baseUrl/posts';
  static String taggedPosts(String userId) => '$baseUrl/posts/tagged/$userId';
  static String likePost(String postId) => '$baseUrl/posts/$postId/like';
  static String commentPost(String postId) => '$baseUrl/posts/$postId/comments';

  // 4. Story Endpoints
  static String get stories => '$baseUrl/stories';
}
