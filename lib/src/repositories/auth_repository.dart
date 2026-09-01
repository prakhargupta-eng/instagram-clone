import 'package:fpdart/fpdart.dart';
import '../models/failure.dart';
import '../models/user.dart';
import '../services/api_endpoints.dart';
import 'api_client.dart';

class AuthRepository {
  static final AuthRepository instance = AuthRepository._internal();
  factory AuthRepository() => instance;
  AuthRepository._internal();

  final ApiClient _apiClient = ApiClient.instance;

  /// Register User
  /// `POST /api/v1/auth/register`
  Future<Either<Failure, AppUser>> register({
    required String username,
    required String fullName,
    required String email,
    required String password,
  }) async {
    _apiClient.setLoading(true);
    try {
      final response = await _apiClient.postRequest(
        ApiEndpoints.register,
        requireAuth: false,
        body: {
          'username': username,
          'fullName': fullName,
          'email': email,
          'password': password,
        },
      );

      final data = _apiClient.handleResponse(response);
      final token = data['token'] as String;
      final userData = data['user'] as Map<String, dynamic>;

      await _apiClient.saveSession(token, userData);
      return Right(_apiClient.currentUser!);
    } on ApiException catch (e) {
      return Left(Failure(e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(Failure(e.toString()));
    } finally {
      _apiClient.setLoading(false);
    }
  }

  /// Login User
  /// `POST /api/v1/auth/login`
  Future<Either<Failure, AppUser>> login({
    required String email,
    required String password,
  }) async {
    _apiClient.setLoading(true);
    try {
      final response = await _apiClient.postRequest(
        ApiEndpoints.login,
        requireAuth: false,
        body: {'email': email, 'password': password},
      );

      final data = _apiClient.handleResponse(response);
      final token = data['token'] as String;
      final userData = data['user'] as Map<String, dynamic>;

      await _apiClient.saveSession(token, userData);
      return Right(_apiClient.currentUser!);
    } on ApiException catch (e) {
      return Left(Failure(e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(Failure(e.toString()));
    } finally {
      _apiClient.setLoading(false);
    }
  }

  /// Delete Account
  /// `POST /api/v1/auth/delete`
  Future<Either<Failure, void>> deleteAccount() async {
    try {
      final response = await _apiClient.postRequest(
        ApiEndpoints.deleteAccount,
        requireAuth: true,
      );
      _apiClient.handleResponse(response);
      await logout();
      return const Right(null);
    } on ApiException catch (e) {
      return Left(Failure(e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  /// Logout
  Future<void> logout() async {
    await _apiClient.logout();
  }
}
