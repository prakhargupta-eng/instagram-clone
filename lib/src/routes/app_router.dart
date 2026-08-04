import 'package:flutter/material.dart';
import '../constants.dart';
import '../models/post.dart';
import '../services/auth_service.dart';
import '../services/feed_service.dart';
import '../screens/auth/login_screen.dart';
import '../screens/home/home_shell.dart';
import '../screens/profile/details_screen.dart';
import 'app_routes.dart';

class AppRouter {
  static Route generate(
    RouteSettings settings, {
    required AuthService authService,
    required bool ready,
  }) {
    switch (settings.name) {
      case AppRoutes.home:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => ready
              ? AnimatedBuilder(
                  animation: authService,
                  builder: (context, _) {
                    return authService.isLoggedIn
                        ? HomeShell(authService: authService)
                        : LoginScreen(authService: authService);
                  },
                )
              : const Scaffold(
                  backgroundColor: AppColors.surface,
                  body: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
        );

      case AppRoutes.detail:
        final args = settings.arguments as Map<String, dynamic>;
        final post = args['post'] as Post;
        final feedService = args['feedService'] as FeedService;

        return MaterialPageRoute(
          settings: settings,
          builder: (_) => DetailsScreen(
            post: post,
            feedService: feedService,
          ),
        );

      default:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const Scaffold(
            body: Center(
              child: Text('Page not found'),
            ),
          ),
        );
    }
  }
}
