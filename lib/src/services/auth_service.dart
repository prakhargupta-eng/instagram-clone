import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

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
  String _sessionKey = '';
  String get sessionKey => _sessionKey;

  List<AppUser> get registeredUsers => _registeredUsers;

  static final RegExp _emailRegex = RegExp(r'^[\w\.\-]+@[\w\-]+\.\w+$');

  /// Restores the persisted session (called once at startup).
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      final box = await Hive.openBox('auth_box');
      final storedUsers = box.get(_kRegisteredUsers) as String?;
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
      final storedPasswords = box.get(_kPasswords) as String?;
      if (storedPasswords != null) {
        try {
          final map = jsonDecode(storedPasswords) as Map<String, dynamic>;
          _passwords
            ..clear()
            ..addAll(map.map((k, v) => MapEntry(k, v as String)));
        } catch (_) {}
      }
      final storedSession = box.get(_kSessionUser) as String?;
      if (storedSession != null) {
        try {
          final data = jsonDecode(storedSession) as Map<String, dynamic>;
          final id = data['id'] as String;
          _currentUser = _registeredUsers.where((u) => u.id == id).firstOrNull ??
              AppUser.fromJson(data);
          _sessionKey = DateTime.now().millisecondsSinceEpoch.toString();
        } catch (_) {
          _currentUser = null;
        }
      }
    } catch (e) {
      debugPrint('AuthService init error: $e');
    }
    notifyListeners();
  }

  Future<void> _saveSession(AppUser user) async {
    final box = await Hive.openBox('auth_box');
    await box.put(_kSessionUser, jsonEncode(user.toJson()));
    await box.put(
      _kRegisteredUsers,
      jsonEncode(_registeredUsers.map((u) => u.toJson()).toList()),
    );
    await box.put(_kPasswords, jsonEncode(_passwords));
  }

  Future<void> _clearSession() async {
    final box = await Hive.openBox('auth_box');
    await box.delete(_kSessionUser);
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
    _sessionKey = DateTime.now().millisecondsSinceEpoch.toString();
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
    final box = await Hive.openBox('auth_box');
    await box.delete(_kSessionUser);
    await box.put(
      _kRegisteredUsers,
      jsonEncode(_registeredUsers.map((u) => u.toJson()).toList()),
    );
    await box.put(_kPasswords, jsonEncode(_passwords));
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
