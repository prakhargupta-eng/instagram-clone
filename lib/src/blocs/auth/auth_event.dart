import 'auth_state.dart';

abstract class AuthEvent {
  const AuthEvent();
}

class AuthInitRequested extends AuthEvent {
  const AuthInitRequested();
}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;
  
  const LoginRequested({required this.email, required this.password});
}

class SignupRequested extends AuthEvent {
  final String email;
  final String username;
  final String fullName;
  final String password;
  
  const SignupRequested({
    required this.email,
    required this.username,
    required this.fullName,
    required this.password,
  });
}

class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

/// Fired after a screen-level login/signup completes successfully.
/// Skips [AuthLoading] so the current screen stays visible.
class AuthStatusChanged extends AuthEvent {
  final AuthState newState;
  const AuthStatusChanged(this.newState);
}
