import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'blocs/auth/auth_bloc.dart';
import 'blocs/auth/auth_event.dart';
import 'blocs/auth/auth_state.dart';
import 'constants.dart';
import 'services/auth_service.dart';
import 'services/theme_service.dart';
import 'theme.dart';
import 'screens/auth/login/login_screen.dart';
import 'screens/home/home_shell.dart';

import 'routes/app_router.dart';

class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.authService,
    required this.themeService,
    required super.child,
  });

  final AuthService authService;
  final ThemeService themeService;

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found in context');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      authService != oldWidget.authService ||
      themeService != oldWidget.themeService;
}

/// Global helper to check if dark mode is active.
/// Usage: `isDark(context)` anywhere in the app.
bool isDark(BuildContext context) =>
    AppScope.of(context).themeService.isDarkMode;

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

class InstaCloneApp extends StatefulWidget {
  const InstaCloneApp({super.key});

  @override
  State<InstaCloneApp> createState() => _InstaCloneAppState();
}

class _InstaCloneAppState extends State<InstaCloneApp> {
  late final AuthService _authService;
  late final ThemeService _themeService;

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
    _themeService = ThemeService();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      authService: _authService,
      themeService: _themeService,
      child: BlocProvider<AuthBloc>(
        create: (context) =>
            AuthBloc(authService: _authService)..add(const AuthInitRequested()),
        child: ListenableBuilder(
          listenable: _themeService,
          builder: (context, child) {
            return MaterialApp(
              title: AppStrings.appTitle,
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light(),
              darkTheme: AppTheme.dark(),
              themeMode: _themeService.themeMode,
              themeAnimationDuration: const Duration(milliseconds: 500),
              themeAnimationCurve: Curves.easeInOut,
              navigatorObservers: [routeObserver],
              home: BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  if (state is AuthAuthenticated) {
                    return HomeShell(authService: _authService);
                  } else if (state is AuthUnauthenticated ||
                      state is AuthFailure) {
                    return LoginScreen(authService: _authService);
                  }
                  // return const Scaffold(
                  //   backgroundColor: AppColors.surface,
                  //   body: Center(
                  //     child: CircularProgressIndicator(
                  //       color: AppColors.primary,
                  //     ),
                  //   ),
                  // );
                  return const SizedBox.shrink();
                },
              ),
              onGenerateRoute: (settings) => AppRouter.generate(
                settings,
                authService: _authService,
                ready: true,
              ),
            );
          },
        ),
      ),
    );
  }
}
