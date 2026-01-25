import 'package:Readme/features/auth/presentation/pages/login_with_email.dart';
import 'package:Readme/features/auth/presentation/pages/welcome_screen.dart';
import 'package:Readme/features/auth/presentation/pages/signup_screen.dart';
import 'package:Readme/features/create_blog_page/presentation/pages/create_blog_screen.dart';
import 'package:Readme/features/home_page/presentation/pages/home_screen.dart';
import 'package:Readme/features/profile_page/presentation/screens/edit_profile_screen.dart';
import 'package:Readme/features/profile_page/presentation/screens/profile_screen.dart';
import 'package:Readme/features/splash/presentation/pages/splash_screen.dart';
import 'package:Readme/features/main_action/presentation/main_action_screen.dart';
import 'package:Readme/features/search/presentation/pages/search_screen.dart';
import 'package:Readme/features/trending/presentation/pages/trending_screen.dart';
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
        builder: (context, state) => const CreateScreen(),
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
      // ShellRoute for bottom navigation bar
      ShellRoute(
        builder: (context, state, child) {
          return MainActionScreen(child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/search',
            name: 'search',
            builder: (context, state) => const SearchScreen(),
          ),
          GoRoute(
            path: '/trending',
            name: 'trending',
            builder: (context, state) => const TrendingScreen(),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/create',
        name: 'create',
        builder: (context, state) => const CreateBlogScreen(),
      ),
    ],
  );
}