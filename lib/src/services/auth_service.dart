import 'package:flutter/foundation.dart';

import '../constants.dart';
import '../data/mock_data.dart';
import '../models/user.dart';
import '../repositories/api_client.dart';
import '../repositories/auth_repository.dart';
import '../repositories/user_repository.dart';

class AuthResult {
  final bool success;
  final String? error;
  final AppUser? user;

  const AuthResult({required this.success, this.error, this.user});
}

class AuthService extends ChangeNotifier {
  final Map<String, String> _passwords = {
    for (final u in MockDatabase.users) u.email: 'password123',
  };

  final List<AppUser> _registeredUsers = List.of(MockDatabase.users);

  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool _initialized = false;
  String _sessionKey = '';
  String get sessionKey => _sessionKey;

  List<AppUser> get registeredUsers => _registeredUsers;

  static final RegExp _emailRegex = RegExp(r'^[\w\.\-]+@[\w\-]+\.\w+$');

  /// Restores the persisted session from API / SharedPreferences (called once at startup).
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      await ApiClient.instance.initSession();
      _currentUser = ApiClient.instance.currentUser;
      
      ApiClient.instance.addListener(() {
        if (ApiClient.instance.currentUser == null && _currentUser != null) {
          _currentUser = null;
          notifyListeners();
        }
      });

      if (_currentUser != null) {
        _sessionKey = DateTime.now().millisecondsSinceEpoch.toString();
      }
    } catch (e) {
      debugPrint('AuthService init REST error: $e');
    }
    notifyListeners();
  }

  Future<AuthResult> login(String email, String password) async {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty || password.isEmpty) {
      return const AuthResult(success: false, error: AppStrings.fillAllFields);
    }
    if (!_emailRegex.hasMatch(normalized)) {
      return const AuthResult(success: false, error: AppStrings.invalidEmail);
    }

    final result = await AuthRepository.instance.login(
      email: normalized,
      password: password,
    );

    return result.fold(
      (failure) => AuthResult(success: false, error: failure.message),
      (user) {
        _currentUser = user;
        _sessionKey = DateTime.now().millisecondsSinceEpoch.toString();
        notifyListeners();
        return AuthResult(success: true, user: user);
      },
    );
  }

  Future<AuthResult> signup({
    required String email,
    required String username,
    required String fullName,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedUsername = username.trim().toLowerCase();
    if (normalizedEmail.isEmpty ||
        normalizedUsername.isEmpty ||
        fullName.isEmpty ||
        password.isEmpty) {
      return const AuthResult(success: false, error: AppStrings.fillAllFields);
    }
    if (!_emailRegex.hasMatch(normalizedEmail)) {
      return const AuthResult(success: false, error: AppStrings.invalidEmail);
    }
    if (password.length < 6) {
      return const AuthResult(
        success: false,
        error: AppStrings.passwordTooShort,
      );
    }

    final result = await AuthRepository.instance.register(
      username: normalizedUsername,
      fullName: fullName.trim(),
      email: normalizedEmail,
      password: password,
    );

    return result.fold(
      (failure) => AuthResult(success: false, error: failure.message),
      (user) {
        _currentUser = user;
        _sessionKey = DateTime.now().millisecondsSinceEpoch.toString();
        notifyListeners();
        return AuthResult(success: true, user: user);
      },
    );
  }

  Future<void> logout() async {
    _currentUser = null;
    await AuthRepository.instance.logout();
    notifyListeners();
  }

  Future<void> deleteAccount() async {
    final id = _currentUser?.id;
    if (id == null) return;
    
    final result = await AuthRepository.instance.deleteAccount();
    
    result.fold(
      (failure) {
        debugPrint('REST API deleteAccount error: ${failure.message}');
        throw Exception(failure.message);
      },
      (_) {
        _registeredUsers.removeWhere((u) => u.id == id);
        _currentUser = null;
        notifyListeners();
      },
    );
  }

  Future<AuthResult> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final user = _currentUser;
    if (user == null) {
      return const AuthResult(success: false, error: 'User is not logged in.');
    }
    final email = user.email;
    final currentPassword = _passwords[email];
    if (currentPassword != oldPassword) {
      return const AuthResult(
        success: false,
        error: 'Incorrect current password.',
      );
    }
    if (newPassword.length < 6) {
      return const AuthResult(
        success: false,
        error: AppStrings.passwordTooShort,
      );
    }
    _passwords[email] = newPassword;
    notifyListeners();
    return AuthResult(success: true, user: user);
  }

  void syncCurrentUser(AppUser updated) {
    final index = _registeredUsers.indexWhere((u) => u.id == updated.id);
    if (index != -1) _registeredUsers[index] = updated;
    _currentUser = updated;
    notifyListeners();
  }

  void updateCurrentUser(AppUser updated) async {
    syncCurrentUser(updated);

    final result = await UserRepository.instance.updateProfile(
      fullName: updated.fullName,
      bio: updated.bio,
      avatarUrl: updated.avatarUrl,
      username: updated.username,
      isPrivate: updated.isPrivate,
      website: updated.website,
      gender: updated.gender,
    );

    result.fold(
      (failure) => debugPrint('REST API updateProfile error: ${failure.message}'),
      (_) {},
    );
  }
}
