import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';
import '../data/mock_data.dart';
import '../models/user.dart';

class AuthResult {
  final bool success;
  final String? error;
  final AppUser? user;

  const AuthResult({required this.success, this.error, this.user});
}

class AuthService extends ChangeNotifier {
  static const _kSessionUser = 'session_user';
  static const _kRegisteredUsers = 'registered_users';
  static const _kPasswords = 'passwords';

  final Map<String, String> _passwords = {
    for (final u in MockDatabase.users) u.email: 'password123',
  };

  final List<AppUser> _registeredUsers = List.of(MockDatabase.users);

  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool _initialized = false;

  List<AppUser> get registeredUsers => _registeredUsers;

  static final RegExp _emailRegex = RegExp(r'^[\w\.\-]+@[\w\-]+\.\w+$');

  /// Restores the persisted session (called once at startup).
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    final prefs = await SharedPreferences.getInstance();
    final storedUsers = prefs.getString(_kRegisteredUsers);
    if (storedUsers != null) {
      try {
        final list = (jsonDecode(storedUsers) as List)
            .map((e) => AppUser.fromJson(e as Map<String, dynamic>))
            .toList();
        _registeredUsers
          ..clear()
          ..addAll(list);
      } catch (_) {}
    }
    final storedPasswords = prefs.getString(_kPasswords);
    if (storedPasswords != null) {
      try {
        final map = jsonDecode(storedPasswords) as Map<String, dynamic>;
        _passwords
          ..clear()
          ..addAll(map.map((k, v) => MapEntry(k, v as String)));
      } catch (_) {}
    }
    final storedSession = prefs.getString(_kSessionUser);
    if (storedSession != null) {
      try {
        final data = jsonDecode(storedSession) as Map<String, dynamic>;
        final id = data['id'] as String;
        _currentUser = _registeredUsers.where((u) => u.id == id).firstOrNull ??
            AppUser.fromJson(data);
      } catch (_) {
        _currentUser = null;
      }
    }
    notifyListeners();
  }

  Future<void> _saveSession(AppUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSessionUser, jsonEncode(user.toJson()));
    await prefs.setString(
      _kRegisteredUsers,
      jsonEncode(_registeredUsers.map((u) => u.toJson()).toList()),
    );
    await prefs.setString(_kPasswords, jsonEncode(_passwords));
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kSessionUser);
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
    final user = _registeredUsers.where((u) => u.email == normalized).firstOrNull;
    if (user == null || _passwords[normalized] != password) {
      return const AuthResult(
        success: false,
        error: AppStrings.wrongCredentials,
      );
    }
    _currentUser = user;
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
      return const AuthResult(success: false, error: AppStrings.emailAlreadyTaken);
    }
    if (_registeredUsers.any((u) => u.username == normalizedUsername)) {
      return const AuthResult(success: false, error: AppStrings.usernameAlreadyTaken);
    }
    if (password.length < 6) {
      return const AuthResult(success: false, error: AppStrings.passwordTooShort);
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
    await _saveSession(user);
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kSessionUser);
    await prefs.setString(
      _kRegisteredUsers,
      jsonEncode(_registeredUsers.map((u) => u.toJson()).toList()),
    );
    await prefs.setString(_kPasswords, jsonEncode(_passwords));
    notifyListeners();
  }

  void updateCurrentUser(AppUser updated) {
    final index = _registeredUsers.indexWhere((u) => u.id == updated.id);
    if (index != -1) _registeredUsers[index] = updated;
    _currentUser = updated;
    _saveSession(updated);
    notifyListeners();
  }
}
