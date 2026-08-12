import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/auth_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService authService;

  AuthBloc({required this.authService}) : super(const AuthInitial()) {
    on<AuthInitRequested>(_onInitRequested);
    on<LoginRequested>(_onLoginRequested);
    on<SignupRequested>(_onSignupRequested);
    on<LogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onInitRequested(AuthInitRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    await authService.init();
    if (authService.isLoggedIn) {
      emit(AuthAuthenticated(authService.currentUser!));
    } else {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onLoginRequested(LoginRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    final result = await authService.login(event.email, event.password);
    if (result.success && result.user != null) {
      emit(AuthAuthenticated(result.user!));
    } else {
      emit(AuthFailure(result.error ?? 'Authentication failed'));
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onSignupRequested(SignupRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    final result = await authService.signup(
      email: event.email,
      username: event.username,
      fullName: event.fullName,
      password: event.password,
    );
    if (result.success && result.user != null) {
      emit(AuthAuthenticated(result.user!));
    } else {
      emit(AuthFailure(result.error ?? 'Registration failed'));
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onLogoutRequested(LogoutRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    await authService.logout();
    emit(const AuthUnauthenticated());
  }
}
