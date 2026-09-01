import 'package:fpdart/fpdart.dart';
import '../models/failure.dart';
import '../models/post.dart';
import '../services/api_endpoints.dart';
import 'api_client.dart';

class PostRepository {
  static final PostRepository instance = PostRepository._internal();
  factory PostRepository() => instance;
  PostRepository._internal();

  final ApiClient _apiClient = ApiClient.instance;

  /// Get Feed Posts
  /// `GET /api/v1/posts/feed`
  Future<Either<Failure, List<Post>>> getFeedPosts() async {
    try {
      final response = await _apiClient.getRequest(ApiEndpoints.feed, requireAuth: true);
      final data = _apiClient.handleResponse(response);
      final List<dynamic> jsonList = data['data'] ?? [];
      final posts = jsonList
          .map((json) => Post.fromJson(json as Map<String, dynamic>))
          .toList();
      return Right(posts);
    } on ApiException catch (e) {
      return Left(Failure(e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  /// Get User Posts
  /// `GET /api/v1/users/:userId/posts` or `GET /api/v1/users/posts`
  Future<Either<Failure, List<Post>>> getUserPosts([String? userId]) async {
    try {
      final response = await _apiClient.getRequest(ApiEndpoints.userPosts(userId), requireAuth: true);
      final data = _apiClient.handleResponse(response);
      final List<dynamic> jsonList = data['data'] ?? [];
      final posts = jsonList
          .map((json) => Post.fromJson(json as Map<String, dynamic>))
          .toList();
      return Right(posts);
    } on ApiException catch (e) {
      return Left(Failure(e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  /// Get Reels
  /// `GET /api/v1/reels?page=...&limit=...`
  Future<Either<Failure, List<Post>>> getReels({int page = 1, int limit = 10}) async {
    try {
      final response = await _apiClient.getRequest(ApiEndpoints.reels(page: page, limit: limit), requireAuth: true);
      final data = _apiClient.handleResponse(response);
      final List<dynamic> jsonList = data['data'] ?? [];
      final posts = jsonList
          .map((json) => Post.fromJson(json as Map<String, dynamic>))
          .toList();
      return Right(posts);
    } on ApiException catch (e) {
      return Left(Failure(e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  /// Get Explore Posts by Category
  /// `GET /api/v1/posts/explore?category=...&page=...&limit=...`
  Future<Either<Failure, List<Post>>> getExplorePostsByCategory(
    String category, {
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await _apiClient.getRequest(
        ApiEndpoints.exploreCategory(category, page: page, limit: limit),
        requireAuth: true,
      );
      final data = _apiClient.handleResponse(response);
      final List<dynamic> jsonList = data['data'] ?? [];
      final posts = jsonList
          .map((json) => Post.fromJson(json as Map<String, dynamic>))
          .toList();
      return Right(posts);
    } on ApiException catch (e) {
      return Left(Failure(e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  /// Create Post
  /// `POST /api/v1/posts`
  Future<Either<Failure, Post>> createPost({
    required String imageUrl,
    String videoUrl = '',
    required String caption,
    String? location,
    String? music,
    bool isVideo = false,
    List<String> taggedUserIds = const [],
  }) async {
    _apiClient.setLoading(true);
    try {
      final response = await _apiClient.postRequest(
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
      final data = _apiClient.handleResponse(response);
      return Right(Post.fromJson(data));
    } on ApiException catch (e) {
      return Left(Failure(e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(Failure(e.toString()));
    } finally {
      _apiClient.setLoading(false);
    }
  }

  /// Get Tagged Posts for Profile Tab
  /// `GET /api/v1/posts/tagged/:userId`
  Future<Either<Failure, List<Post>>> getTaggedPosts(String userId) async {
    try {
      final response = await _apiClient.getRequest(
        ApiEndpoints.taggedPosts(userId),
        requireAuth: true,
      );
      final data = _apiClient.handleResponse(response);
      final List<dynamic> jsonList = data['data'] ?? [];
      final posts = jsonList.map((e) => Post.fromJson(e as Map<String, dynamic>)).toList();
      return Right(posts);
    } on ApiException catch (e) {
      return Left(Failure(e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  /// Get Reels Feed
  /// `GET /api/v1/posts/reels`
  Future<Either<Failure, List<Post>>> getReelsFeed() async {
    try {
      final response = await _apiClient.getRequest(ApiEndpoints.reels(), requireAuth: false);
      final data = _apiClient.handleResponse(response);
      final List<dynamic> jsonList = data['data'] ?? [];
      final posts = jsonList.map((e) => Post.fromJson(e as Map<String, dynamic>)).toList();
      return Right(posts);
    } on ApiException catch (e) {
      return Left(Failure(e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  /// Get Stories Feed
  /// `GET /api/v1/stories`
  Future<Either<Failure, List<dynamic>>> getStories() async {
    try {
      final response = await _apiClient.getRequest(ApiEndpoints.stories, requireAuth: false);
      final data = _apiClient.handleResponse(response);
      return Right(data['data'] as List<dynamic>? ?? []);
    } on ApiException catch (e) {
      return Left(Failure(e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  /// Create Story
  /// `POST /api/v1/stories`
  Future<Either<Failure, dynamic>> createStory({
    required String imageUrl,
    bool isVideo = false,
  }) async {
    try {
      final response = await _apiClient.postRequest(
        ApiEndpoints.stories,
        requireAuth: true,
        body: {'imageUrl': imageUrl, 'isVideo': isVideo},
      );
      return Right(_apiClient.handleResponse(response));
    } on ApiException catch (e) {
      return Left(Failure(e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  /// Like / Unlike Post
  /// `POST /api/v1/posts/:postId/like`
  Future<Either<Failure, bool>> toggleLike(String postId) async {
    try {
      final response = await _apiClient.postRequest(
        ApiEndpoints.likePost(postId),
        requireAuth: true,
      );
      final data = _apiClient.handleResponse(response);
      return Right(data['liked'] as bool? ?? false);
    } on ApiException catch (e) {
      return Left(Failure(e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  /// Add Comment to Post
  /// `POST /api/v1/posts/:postId/comments`
  Future<Either<Failure, Comment>> addComment(String postId, String text) async {
    try {
      final response = await _apiClient.postRequest(
        ApiEndpoints.commentPost(postId),
        requireAuth: true,
        body: {'text': text},
      );
      final data = _apiClient.handleResponse(response);
      return Right(Comment.fromJson(data));
    } on ApiException catch (e) {
      return Left(Failure(e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  /// Toggle Bookmark
  /// `POST /api/v1/posts/:postId/bookmark`
  Future<Either<Failure, void>> toggleBookmark(String postId) async {
    try {
      final response = await _apiClient.postRequest(
        ApiEndpoints.bookmarkPost(postId),
        requireAuth: true,
      );
      _apiClient.handleResponse(response);
      return const Right(null);
    } on ApiException catch (e) {
      return Left(Failure(e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  /// Get Bookmarks
  /// `GET /api/v1/users/bookmarks?page=...&limit=...`
  Future<Either<Failure, List<Post>>> getBookmarks({int page = 1, int limit = 10}) async {
    try {
      final response = await _apiClient.getRequest(
        '${ApiEndpoints.getBookmarks}?page=$page&limit=$limit',
        requireAuth: true,
      );
      final data = _apiClient.handleResponse(response);
      final List<dynamic> jsonList = data['bookmarks'] ?? data['data'] ?? [];
      final posts = jsonList.map((e) {
        final postJson = e['post'] as Map<String, dynamic>? ?? e as Map<String, dynamic>;
        return Post.fromJson(postJson);
      }).toList();
      return Right(posts);
    } on ApiException catch (e) {
      return Left(Failure(e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }
}
