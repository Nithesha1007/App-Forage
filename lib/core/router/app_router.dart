import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../screens/splash/splash_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/templates/templates_screen.dart';
import '../../screens/builder/builder_screen.dart';
import '../../screens/preview/preview_screen.dart';
import '../../screens/publish/publish_screen.dart';
import '../../screens/admin/admin_dashboard.dart';

class AppRouter {
  static final _key = GlobalKey<NavigatorState>();

  static final router = GoRouter(
    navigatorKey: _key,
    initialLocation: '/splash',
    redirect: (context, state) {
      final auth = context.read<AuthProvider>();
      final path = state.fullPath ?? '';

      // Always let splash through
      if (path == '/splash') return null;

      // Not logged in → login
      if (!auth.isAuthenticated && path != '/login') return '/login';

      // Logged in but role not loaded yet → stay (splash handles wait)
      if (auth.isAuthenticated && !auth.roleLoaded) return null;

      // ✅ Role-based redirect after login
      if (auth.isAuthenticated && path == '/login') {
        return auth.isAdmin ? '/admin' : '/home';
      }

      // Admin trying to access user routes → redirect to admin
      if (auth.isAdmin && (path == '/home' || path == '/templates')) {
        return '/admin';
      }

      // Normal user trying to access admin → redirect to home
      if (!auth.isAdmin && path.startsWith('/admin')) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (c, s) => const SplashScreen()),
      GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),

      // ── User routes ──────────────────────────────────────────────────
      GoRoute(path: '/home', builder: (c, s) => const HomeScreen()),
      GoRoute(path: '/templates', builder: (c, s) => const TemplatesScreen()),
      GoRoute(
        path: '/builder/:projectId',
        builder: (c, s) =>
            BuilderScreen(projectId: s.pathParameters['projectId']!),
      ),
      GoRoute(
        path: '/preview/:projectId',
        builder: (c, s) =>
            PreviewScreen(projectId: s.pathParameters['projectId']!),
      ),
      GoRoute(
        path: '/publish/:projectId',
        builder: (c, s) =>
            PublishScreen(projectId: s.pathParameters['projectId']!),
      ),

      // ── Admin routes ─────────────────────────────────────────────────
      GoRoute(path: '/admin', builder: (c, s) => const AdminDashboard()),
    ],
  );
}
