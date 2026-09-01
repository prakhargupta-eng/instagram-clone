import 'package:fpdart/fpdart.dart';
import '../models/failure.dart';
import '../models/user.dart';
import '../services/api_endpoints.dart';
import 'api_client.dart';

class UserRepository {
  static final UserRepository instance = UserRepository._internal();
  factory UserRepository() => instance;
  UserRepository._internal();

  final ApiClient _apiClient = ApiClient.instance;

  /// Get User Profile
  /// `GET /api/v1/users/profile/:userId`
  Future<Either<Failure, AppUser>> getUserProfile([String? userId]) async {
    try {
      final response = await _apiClient.getRequest(
        ApiEndpoints.userProfile(userId),
        requireAuth: true,
      );

      final data = _apiClient.handleResponse(response);
      return Right(AppUser.fromJson(data));
    } on ApiException catch (e) {
      return Left(Failure(e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  /// Update User Profile
  /// `PUT /api/v1/users/profile`
  Future<Either<Failure, AppUser>> updateProfile({
    String? fullName,
    String? bio,
    String? avatarUrl,
    String? username,
    bool? isPrivate,
    String? website,
    String? gender,
  }) async {
    _apiClient.setLoading(true);
    try {
      final body = <String, dynamic>{};
      if (fullName != null) body['fullName'] = fullName;
      if (bio != null) body['bio'] = bio;
      if (avatarUrl != null) body['avatarUrl'] = avatarUrl;
      if (username != null) body['username'] = username;
      if (isPrivate != null) body['isPrivate'] = isPrivate;
      if (website != null) body['website'] = website;
      if (gender != null) body['gender'] = gender;

      final response = await _apiClient.putRequest(
        ApiEndpoints.updateProfile,
        requireAuth: true,
        body: body,
      );

      final data = _apiClient.handleResponse(response);
      final updatedUser = AppUser.fromJson(data);
      _apiClient.updateCurrentUser(updatedUser);
      await _apiClient.updateStoredUser(data);

      return Right(updatedUser);
    } on ApiException catch (e) {
      return Left(Failure(e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(Failure(e.toString()));
    } finally {
      _apiClient.setLoading(false);
    }
  }

  /// Follow / Unfollow User
  /// `POST /api/v1/users/:userId/follow`
  Future<Either<Failure, bool>> toggleFollow(String userId) async {
    try {
      final response = await _apiClient.postRequest(
        ApiEndpoints.followUser(userId),
        requireAuth: true,
      );

      final data = _apiClient.handleResponse(response);
      return Right(data['following'] as bool? ?? false);
    } on ApiException catch (e) {
      return Left(Failure(e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  /// Search
  /// `GET /api/v1/search?q=query`
  Future<Either<Failure, List<dynamic>>> search(String query) async {
    if (query.trim().isEmpty) return const Right([]);
    try {
      final response = await _apiClient.getRequest(
        ApiEndpoints.search(query),
        requireAuth: true,
      );
      final data = _apiClient.handleResponse(response);
      return Right(data['data'] as List<dynamic>? ?? []);
    } on ApiException catch (e) {
      return Left(Failure(e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }
}
