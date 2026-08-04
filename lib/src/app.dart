import 'package:flutter/material.dart';

import 'constants.dart';
import 'services/auth_service.dart';
import 'theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_shell.dart';

import 'routes/app_router.dart';

class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.authService, required super.child});

  final AuthService authService;

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found in context');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) => authService != oldWidget.authService;
}

class InstaCloneApp extends StatefulWidget {
  const InstaCloneApp({super.key});

  @override
  State<InstaCloneApp> createState() => _InstaCloneAppState();
}

class _InstaCloneAppState extends State<InstaCloneApp> {
  late final AuthService _authService;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
    _authService.init().then((_) {
      if (mounted) setState(() => _ready = true);
    }).catchError((e) {
      debugPrint('Initialization error: $e');
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      authService: _authService,
      child: MaterialApp(
        title: AppStrings.appTitle,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: _ready
            ? AnimatedBuilder(
                animation: _authService,
                builder: (context, _) {
                  return _authService.isLoggedIn
                      ? HomeShell(authService: _authService)
                      : LoginScreen(authService: _authService);
                },
              )
            : const Scaffold(
                backgroundColor: AppColors.surface,
                body: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
        onGenerateRoute: (settings) => AppRouter.generate(
          settings,
          authService: _authService,
          ready: _ready,
        ),
      ),
    );
  }
}

