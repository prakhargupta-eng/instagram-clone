import 'package:flutter/material.dart';

import '../../../blocs/auth/auth_bloc.dart';
import '../../../blocs/auth/auth_event.dart';
import '../../../blocs/auth/auth_state.dart';
import '../../../services/auth_service.dart';

/// ViewModel for the Signup screen.
class SignupViewModel extends ChangeNotifier {
  SignupViewModel({required this.authBloc, required this.authService});

  final AuthBloc authBloc;
  final AuthService authService;

  // ── Controllers ──────────────────────────────────────────────────────
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // ── State ────────────────────────────────────────────────────────────
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _obscurePassword = true;
  bool get obscurePassword => _obscurePassword;

  // ── Actions ──────────────────────────────────────────────────────────

  /// Toggle password field visibility.
  void toggleObscure() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  /// Validate the form and call the auth API directly.
  Future<String?> submit() async {
    if (!formKey.currentState!.validate()) return null;

    _isLoading = true;
    notifyListeners();

    final result = await authService.signup(
      email: emailController.text.trim(),
      username: usernameController.text.trim(),
      fullName: fullNameController.text.trim(),
      password: passwordController.text,
    );

    if (result.success && result.user != null) {
      // Notify the root Bloc that auth state changed (skipping AuthLoading)
      authBloc.add(AuthStatusChanged(AuthAuthenticated(result.user!)));
      return null;
    } else {
      _isLoading = false;
      notifyListeners();
      return result.error ?? 'Registration failed';
    }
  }

  // ── Cleanup ──────────────────────────────────────────────────────────

  @override
  void dispose() {
    emailController.dispose();
    usernameController.dispose();
    fullNameController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
