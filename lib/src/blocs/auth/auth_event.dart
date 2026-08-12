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
