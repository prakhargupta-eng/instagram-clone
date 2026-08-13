import 'dart:io';

class ApiEndpoints {
  /// Dynamically computes the backend base URL for Android Emulator vs iOS / Web / Desktop.
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000/api/v1';
    }
    return 'http://localhost:3000/api/v1';
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
  static String searchUsers(String query) =>
      '$baseUrl/users/search?q=${Uri.encodeComponent(query)}';

  // 3. Post & Feed Endpoints
  static String get feed => '$baseUrl/posts/feed';
  static String get reels => '$baseUrl/posts/reels';
  static String get createPost => '$baseUrl/posts';
  static String taggedPosts(String userId) => '$baseUrl/posts/tagged/$userId';
  static String likePost(String postId) => '$baseUrl/posts/$postId/like';
  static String commentPost(String postId) => '$baseUrl/posts/$postId/comments';

  // 4. Story Endpoints
  static String get stories => '$baseUrl/stories';
}
