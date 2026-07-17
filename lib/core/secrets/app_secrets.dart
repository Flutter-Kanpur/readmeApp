import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppSecrets {
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';

  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  /// Custom scheme used for auth callbacks (password reset, OAuth, etc.).
  /// Must be allow-listed in Supabase Auth → URL Configuration → Redirect URLs.
  static const String authCallbackUrl =
      'com.flutterkanpur.readme://login-callback/';
}
