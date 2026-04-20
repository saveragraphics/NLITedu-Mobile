import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../features/auth/login_screen.dart';
import '../features/dashboard/tabs_layout.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/course/catalog_screen.dart';
import '../features/course/course_details_screen.dart';
import '../features/course/enrollment_form_screen.dart';
import '../features/dashboard/learning_hub_screen.dart';
import '../features/dashboard/course_content_view.dart';
import '../features/dashboard/achievement_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/profile/personal_info_screen.dart';
import '../features/profile/notifications_settings_screen.dart';
import '../features/profile/security_screen.dart';
import '../features/profile/privacy_policy_screen.dart';
import '../features/profile/terms_and_conditions_screen.dart';
import '../models/course.dart';
import '../models/live_session.dart';
import '../features/course/live_class_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

String _initialLocation() {
  final session = Supabase.instance.client.auth.currentSession;
  return session != null ? '/home' : '/login';
}

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: _initialLocation(),
  redirect: (context, state) {
    final session = Supabase.instance.client.auth.currentSession;
    final isOnLogin = state.uri.path == '/login';
    // If logged in and on login page, redirect to home
    if (session != null && isOnLogin) return '/home';
    // If not logged in and not on login, redirect to login
    if (session == null && !isOnLogin) return '/login';
    // If they manually try /discover, redirect to /catalog
    if (state.uri.path == '/discover') return '/catalog';
    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    // Full screen route taking up the entire display
    GoRoute(
      path: '/course/:slug',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final slug = state.pathParameters['slug']!;
        
        if (state.extra is Course) {
          return CourseDetailsScreen(course: state.extra as Course);
        }

        // Fallback or stub if extra is missing (e.g. direct link)
        final fallbackCourse = Course(
          title: 'Mastering $slug',
          description: 'Dive deep into $slug and master professional skills with our industry-led path.',
          imageUrl: 'https://via.placeholder.com/600x400?text=$slug',
          slug: slug,
          category: 'GENERAL',
          categoryColor: Colors.grey,
        );
        
        return CourseDetailsScreen(course: fallbackCourse);
      },
    ),
    GoRoute(
      path: '/enroll/:slug',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        if (state.extra is Course) {
          return EnrollmentFormScreen(course: state.extra as Course);
        }
        return const Scaffold(body: Center(child: Text('Course data missing')));
      },
    ),
    GoRoute(
      path: '/live-session',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        if (state.extra is LiveSession) {
          return LiveClassScreen(session: state.extra as LiveSession);
        }
        return const Scaffold(body: Center(child: Text('Session data missing')));
      },
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return TabsLayout(child: child);
      },
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/achievements',
          builder: (context, state) => const AchievementScreen(),
        ),
        GoRoute(
          path: '/catalog',
          builder: (context, state) => const CatalogScreen(),
        ),
        GoRoute(
          path: '/learning-hub',
          builder: (context, state) => const LearningHubScreen(),
          routes: [
            GoRoute(
              path: 'view',
              builder: (context, state) {
                if (state.extra is Course) {
                  return CourseContentView(course: state.extra as Course);
                }
                return const Scaffold(body: Center(child: Text('Course data missing')));
              },
            ),
          ],
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
          routes: [
            GoRoute(
              path: 'info',
              builder: (context, state) => const PersonalInfoScreen(),
            ),
            GoRoute(
              path: 'notifications',
              builder: (context, state) => const NotificationsSettingsScreen(),
            ),
            GoRoute(
              path: 'security',
              builder: (context, state) => const SecurityScreen(),
            ),
            GoRoute(
              path: 'privacy',
              builder: (context, state) => const PrivacyPolicyScreen(),
            ),
            GoRoute(
              path: 'terms',
              builder: (context, state) => const TermsAndConditionsScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
