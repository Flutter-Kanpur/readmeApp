import 'package:Readme/features/auth/presentation/pages/login_with_email.dart';
import 'package:Readme/features/auth/presentation/pages/welcome_screen.dart';
import 'package:Readme/features/auth/presentation/pages/signup_screen.dart';
import 'package:Readme/features/home_page/presentation/pages/home_screen.dart';
import 'package:Readme/features/profile_page/presentation/screens/profile_screen.dart';
import 'package:Readme/features/splash/presentation/pages/splash_screen.dart';
import 'package:Readme/features/main_action/presentation/main_action_screen.dart';
import 'package:Readme/features/search/presentation/pages/search_screen.dart';
import 'package:Readme/features/create/presentation/pages/create_screen.dart';
import 'package:Readme/features/trending/presentation/pages/trending_screen.dart';
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
            path: '/create',
            name: 'create',
            builder: (context, state) => const CreateScreen(),
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
    ],
  );
}