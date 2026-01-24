import 'package:Readme/features/auth/presentation/pages/login_with_email.dart';
import 'package:Readme/features/auth/presentation/pages/welcome_screen.dart';
import 'package:Readme/features/auth/presentation/pages/signup_screen.dart';
import 'package:Readme/features/home_page/presentation/pages/home_screen.dart';
import 'package:Readme/features/splash/presentation/pages/splash_screen.dart';
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
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
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
      ),]);
}