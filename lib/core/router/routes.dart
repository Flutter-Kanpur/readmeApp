import 'package:Readme/features/auth/presentation/pages/login_with_email.dart';
import 'package:Readme/features/auth/presentation/pages/welcome_screen.dart';
import 'package:Readme/features/auth/presentation/pages/signup_screen.dart';
import 'package:Readme/features/create_blog_page/presentation/pages/create_blog_screen.dart';
import 'package:Readme/features/create_blog_page/presentation/pages/my_drafts_screen.dart';
import 'package:Readme/features/home_page/presentation/pages/home_screen.dart';
import 'package:Readme/features/profile_page/presentation/screens/edit_profile_screen.dart';
import 'package:Readme/features/profile_page/presentation/screens/profile_screen.dart';
import 'package:Readme/features/splash/presentation/pages/splash_screen.dart';
import 'package:Readme/features/main_action/presentation/main_action_screen.dart';
import 'package:Readme/features/search/presentation/pages/search_screen.dart';
import 'package:Readme/features/communities/presentation/pages/communities_screen.dart';
import 'package:Readme/features/communities/presentation/pages/community_dashboard_screen.dart';
import 'package:Readme/features/communities/presentation/pages/community_detail_screen.dart';
import 'package:Readme/features/communities/domain/entities/community.dart';
import 'package:Readme/features/blog_detail/presentation/pages/blog_detail_screen.dart';
import 'package:Readme/features/home_page/domain/entities/blog.dart';
import 'package:go_router/go_router.dart';

class AppRouter{
  static final GoRouter router = GoRouter(
    initialLocation: '/',
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
      // Edit Profile route outside ShellRoute to hide bottom nav bar
      GoRoute(
        path: '/edit_profile',
        name: 'edit_profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/create',
        name: 'create',
        builder: (context, state) => const CreateBlogScreen(),
      ),
      // Blog Detail route outside ShellRoute to hide bottom nav bar
      GoRoute(
        path: '/blog/:id',
        name: 'blog_detail',
        builder: (context, state) {
          final blog = state.extra as Blog;
          return BlogDetailScreen(blog: blog);
        },
      ),
      GoRoute(
        path: '/community/:slug/dashboard',
        name: 'community_dashboard',
        builder: (context, state) {
          final slug = state.pathParameters['slug']!;
          final community = state.extra as Community?;
          return CommunityDashboardScreen(slug: slug, community: community);
        },
      ),
      GoRoute(
        path: '/community/:slug',
        name: 'community_detail',
        builder: (context, state) {
          final slug = state.pathParameters['slug']!;
          final community = state.extra as Community?;
          return CommunityDetailScreen(slug: slug, community: community);
        },
      ),
      // StatefulShellRoute keeps each tab's state alive across switches so
      // data fetched in initState isn't reloaded every time the user toggles
      // bottom-nav tabs.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainActionScreen(navigationShell: navigationShell);
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
          // Branch order must match the navbar's `_items` order in
          // `app_bottom_nav_bar.dart` so tapping a nav item routes to the
          // matching branch.
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
          // Drafts is the 5th branch so the bottom nav stays visible while
          // the user manages drafts. Index 4 corresponds to the pencil CTA.
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
