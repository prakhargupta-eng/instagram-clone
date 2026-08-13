
import 'package:flutter/foundation.dart';

import '../constants.dart';
import '../data/mock_data.dart';
import '../models/user.dart';
import 'api_service.dart';

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
      await ApiService.instance.initSession();
      _currentUser = ApiService.instance.currentUser;
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

    try {
      final user = await ApiService.instance.login(
        email: normalized,
        password: password,
      );
      _currentUser = user;
      _sessionKey = DateTime.now().millisecondsSinceEpoch.toString();
      notifyListeners();
      return AuthResult(success: true, user: user);
    } catch (apiError) {
      return AuthResult(success: false, error: apiError.toString());
    }
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

    try {
      final user = await ApiService.instance.register(
        username: normalizedUsername,
        fullName: fullName.trim(),
        email: normalizedEmail,
        password: password,
      );
      _currentUser = user;
      _sessionKey = DateTime.now().millisecondsSinceEpoch.toString();
      notifyListeners();
      return AuthResult(success: true, user: user);
    } catch (apiError) {
      return AuthResult(success: false, error: apiError.toString());
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    await ApiService.instance.logout();
    notifyListeners();
  }

  Future<void> deleteAccount() async {
    final id = _currentUser?.id;
    if (id == null) return;
    try {
      await ApiService.instance.deleteAccount();
    } catch (e) {
      debugPrint('REST API deleteAccount error: $e');
    }
    _registeredUsers.removeWhere((u) => u.id == id);
    _currentUser = null;
    notifyListeners();
  }

  Future<AuthResult> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
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

  void updateCurrentUser(AppUser updated) async {
    final index = _registeredUsers.indexWhere((u) => u.id == updated.id);
    if (index != -1) _registeredUsers[index] = updated;
    _currentUser = updated;
    notifyListeners();

    try {
      await ApiService.instance.updateProfile(
        fullName: updated.fullName,
        bio: updated.bio,
        avatarUrl: updated.avatarUrl,
        username: updated.username,
      );
    } catch (e) {
      debugPrint('REST API updateProfile error: $e');
    }
  }
}
