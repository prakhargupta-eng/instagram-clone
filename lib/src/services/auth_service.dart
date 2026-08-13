
import 'package:flutter/foundation.dart';

import '../constants.dart';
import '../data/mock_data.dart';
import '../models/user.dart';
import 'sql_database_helper.dart';

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

  /// Restores the persisted session (called once at startup).
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      final db = SqlDatabaseHelper.instance;

      // Seed mock users on first run if database is empty
      final existingUsers = await db.getAllUsers();
      if (existingUsers.isEmpty) {
        for (final user in MockDatabase.users) {
          await db.insertUser(user);
          await db.setPassword(user.email, 'password123');
        }
      }

      _registeredUsers
        ..clear()
        ..addAll(await db.getAllUsers());

      _passwords
        ..clear()
        ..addAll(await db.getAllCredentials());

      final sessionUserId = await db.getSessionUserId();
      if (sessionUserId != null) {
        _currentUser = _registeredUsers.where((u) => u.id == sessionUserId).firstOrNull;
        if (_currentUser == null) {
          _currentUser = await db.getUser(sessionUserId);
        }
        if (_currentUser != null) {
          _sessionKey = DateTime.now().millisecondsSinceEpoch.toString();
        }
      }
    } catch (e) {
      debugPrint('AuthService init error: $e');
    }
    notifyListeners();
  }

  Future<void> _saveSession(AppUser user) async {
    final db = SqlDatabaseHelper.instance;
    await db.insertUser(user);
    await db.saveSession(user.id);
  }

  Future<void> _clearSession() async {
    final db = SqlDatabaseHelper.instance;
    await db.clearSession();
  }

  Future<AuthResult> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty || password.isEmpty) {
      return const AuthResult(success: false, error: AppStrings.fillAllFields);
    }
    if (!_emailRegex.hasMatch(normalized)) {
      return const AuthResult(success: false, error: AppStrings.invalidEmail);
    }
    final user = _registeredUsers
        .where((u) => u.email == normalized)
        .firstOrNull;
    if (user == null || _passwords[normalized] != password) {
      return const AuthResult(
        success: false,
        error: AppStrings.wrongCredentials,
      );
    }
    _currentUser = user;
    _sessionKey = DateTime.now().millisecondsSinceEpoch.toString();
    await _saveSession(user);
    notifyListeners();
    return AuthResult(success: true, user: user);
  }

  Future<AuthResult> signup({
    required String email,
    required String username,
    required String fullName,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
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
    if (_registeredUsers.any((u) => u.email == normalizedEmail)) {
      return const AuthResult(
        success: false,
        error: AppStrings.emailAlreadyTaken,
      );
    }
    if (_registeredUsers.any((u) => u.username == normalizedUsername)) {
      return const AuthResult(
        success: false,
        error: AppStrings.usernameAlreadyTaken,
      );
    }
    if (password.length < 6) {
      return const AuthResult(
        success: false,
        error: AppStrings.passwordTooShort,
      );
    }
    final user = AppUser(
      id: 'u${DateTime.now().millisecondsSinceEpoch}',
      username: normalizedUsername,
      fullName: fullName.trim(),
      email: normalizedEmail,
      bio: '',
      avatarUrl: 'https://i.pravatar.cc/300?u=$normalizedUsername',
    );
    _registeredUsers.add(user);
    _passwords[normalizedEmail] = password;
    _currentUser = user;
    _sessionKey = DateTime.now().millisecondsSinceEpoch.toString();
    
    final db = SqlDatabaseHelper.instance;
    await db.insertUser(user);
    await db.setPassword(normalizedEmail, password);
    await db.saveSession(user.id);
    notifyListeners();
    return AuthResult(success: true, user: user);
  }

  Future<void> logout() async {
    _currentUser = null;
    await _clearSession();
    notifyListeners();
  }

  Future<void> deleteAccount() async {
    final id = _currentUser?.id;
    if (id == null) return;
    _registeredUsers.removeWhere((u) => u.id == id);
    final email = _currentUser?.email;
    if (email != null) _passwords.remove(email);
    _currentUser = null;
    final db = SqlDatabaseHelper.instance;
    await db.deleteUser(id);
    if (email != null) await db.deletePassword(email);
    await db.clearSession();
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
    await SqlDatabaseHelper.instance.setPassword(email, newPassword);
    notifyListeners();
    return AuthResult(success: true, user: user);
  }

  void updateCurrentUser(AppUser updated) {
    final index = _registeredUsers.indexWhere((u) => u.id == updated.id);
    if (index != -1) _registeredUsers[index] = updated;
    _currentUser = updated;
    _saveSession(updated);
    notifyListeners();
  }
}
