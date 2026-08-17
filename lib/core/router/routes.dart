import 'package:Readme/features/auth/presentation/pages/forgot_password_screen.dart';
import 'package:Readme/features/auth/presentation/pages/login_with_email.dart';
import 'package:Readme/features/auth/presentation/pages/reset_password_screen.dart';
import 'package:Readme/features/auth/presentation/pages/welcome_screen.dart';
import 'package:Readme/features/auth/presentation/pages/signup_screen.dart';
import 'package:Readme/features/create_blog_page/presentation/pages/create_blog_screen.dart';
import 'package:Readme/features/create_blog_page/presentation/pages/my_drafts_screen.dart';
import 'package:Readme/features/home_page/presentation/pages/home_screen.dart';
import 'package:Readme/features/profile_page/presentation/screens/author_profile_screen.dart';
import 'package:Readme/features/profile_page/presentation/screens/edit_profile_screen.dart';
import 'package:Readme/features/profile_page/presentation/screens/profile_screen.dart';
import 'package:Readme/features/splash/presentation/pages/splash_screen.dart';
import 'package:Readme/features/main_action/presentation/main_action_screen.dart';
import 'package:Readme/features/search/presentation/pages/search_screen.dart';
import 'package:Readme/features/communities/presentation/pages/communities_screen.dart';
import 'package:Readme/features/communities/presentation/pages/community_dashboard_screen.dart';
import 'package:Readme/features/communities/presentation/pages/community_detail_screen.dart';
import 'package:Readme/features/communities/domain/entities/community.dart';
import 'package:Readme/features/legal/presentation/pages/privacy_policy_screen.dart';
import 'package:Readme/core/deep_links/article_deep_link.dart';
import 'package:Readme/features/blog_detail/presentation/pages/blog_detail_loader.dart';
import 'package:Readme/features/home_page/domain/entities/blog.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:Readme/core/network/readme_supabase.dart';

CustomTransitionPage<void> _fadeSlideTransitionPage({
  required LocalKey key,
  required Widget child,
  Duration duration = const Duration(milliseconds: 550),
}) {
  return CustomTransitionPage<void>(
    key: key,
    transitionDuration: duration,
    reverseTransitionDuration: const Duration(milliseconds: 400),
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.012),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class AppRouter {
  static final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');

  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    redirect: (context, state) {
      // Platform deep links arrive as /blogs/articles/:id (website path).
      final articleRoute = ArticleDeepLink.routeFor(state.uri);
      if (articleRoute != null && state.matchedLocation != articleRoute) {
        return articleRoute;
      }

      final loggedIn = ReadmeSupabase.client.auth.currentUser != null;
      final location = state.matchedLocation;

      const authLandingRoutes = {
        '/welcome',
        '/signin',
        '/signup',
      };

      // Keep logged-in users out of auth screens so "back" never lands on
      // welcome after Google / email login.
      if (loggedIn && authLandingRoutes.contains(location)) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/welcome',
        name: 'welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/signin',
        name: 'signin',
        builder: (context, state) => const LoginWithEmail(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot_password',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final email = state.extra as String?;
          return ForgotPasswordScreen(initialEmail: email);
        },
      ),
      GoRoute(
        path: '/reset-password',
        name: 'reset_password',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ResetPasswordScreen(),
      ),
      GoRoute(
        path: '/privacy-policy',
        name: 'privacy_policy',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: '/edit_profile',
        name: 'edit_profile',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/profile/:userId',
        name: 'author_profile',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          return AuthorProfileScreen(userId: userId);
        },
      ),
      GoRoute(
        path: '/create',
        name: 'create',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const CreateBlogScreen(),
      ),
      GoRoute(
        path: '/edit/:id',
        name: 'edit_blog',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return CreateBlogScreen(blogId: id);
        },
      ),
      // Full-screen on the root navigator so it stacks above the shell and
      // popping returns to home/search — not to welcome.
      GoRoute(
        path: '/blog/:id',
        name: 'blog_detail',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final blog = state.extra is Blog ? state.extra as Blog : null;
          return BlogDetailLoader(blogId: id, initialBlog: blog);
        },
      ),
      GoRoute(
        path: '/community/:slug/dashboard',
        name: 'community_dashboard',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final slug = state.pathParameters['slug']!;
          final community = state.extra as Community?;
          return CommunityDashboardScreen(slug: slug, community: community);
        },
      ),
      GoRoute(
        path: '/community/:slug',
        name: 'community_detail',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final slug = state.pathParameters['slug']!;
          final community = state.extra as Community?;
          return CommunityDetailScreen(slug: slug, community: community);
        },
      ),
      StatefulShellRoute.indexedStack(
        pageBuilder: (context, state, navigationShell) {
          return _fadeSlideTransitionPage(
            key: state.pageKey,
            child: MainActionScreen(navigationShell: navigationShell),
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                name: 'home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/search',
                name: 'search',
                builder: (context, state) => const SearchScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/trending',
                name: 'trending',
                builder: (context, state) => const CommunitiesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                name: 'profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/drafts',
                name: 'drafts',
                builder: (context, state) => const MyDraftsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
