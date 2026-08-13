import 'package:flutter/material.dart';

import '../../../blocs/auth/auth_bloc.dart';
import '../../../blocs/auth/auth_event.dart';
import '../../../blocs/auth/auth_state.dart';
import '../../../services/auth_service.dart';

/// ViewModel for the Login screen.
///
/// Owns all state (loading, error, obscure, controllers) and business logic.
/// Has zero dependency on [BuildContext] — fully testable.
class LoginViewModel extends ChangeNotifier {
  LoginViewModel({required this.authBloc, required this.authService});

  final AuthBloc authBloc;
  final AuthService authService;

  // ── Controllers ──────────────────────────────────────────────────────
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // ── State ────────────────────────────────────────────────────────────
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  bool _obscurePassword = true;
  bool get obscurePassword => _obscurePassword;

  // ── Actions ──────────────────────────────────────────────────────────

  /// Toggle password field visibility.
  void toggleObscure() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  /// Clear any server-side error (e.g. when user edits a field).
  void clearServerError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  /// Validate the form and dispatch [LoginRequested] to the [AuthBloc].
  Future<String?> submit() async {
    if (!formKey.currentState!.validate()) return null;
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    // Call login API directly here to avoid triggering AuthLoading in the root app
    // which would cause a black screen.
    final result = await authService.login(
      emailController.text.trim(),
      passwordController.text,
    );

    if (result.success && result.user != null) {
      // Notify the root Bloc that auth state changed (skipping AuthLoading)
      authBloc.add(AuthStatusChanged(AuthAuthenticated(result.user!)));
      return null;
    } else {
      _isLoading = false;
      _error = result.error ?? 'Authentication failed';
      notifyListeners();
      return _error;
    }
  }

  /// Fill the form with demo account credentials.
  void fillDemo(String email) {
    emailController.text = email;
    passwordController.text = 'password123';
    notifyListeners();
  }

  // ── Cleanup ──────────────────────────────────────────────────────────

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
