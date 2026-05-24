import 'dart:io';

import 'package:Readme/core/secrets/app_secrets.dart';

class SupabaseConnectivity {
  /// Returns true if the device can reach the configured Supabase project.
  static Future<bool> canReachServer() async {
    final url = AppSecrets.supabaseUrl.trim();
    if (url.isEmpty) return false;

    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) return false;

    final client = HttpClient();
    try {
      final request = await client
          .getUrl(uri.replace(path: '/auth/v1/health'))
          .timeout(const Duration(seconds: 8));
      final response = await request.close().timeout(
        const Duration(seconds: 8),
      );
      await response.drain();
      // Any HTTP response means DNS + TCP worked (401 is expected without a key).
      return response.statusCode > 0;
    } on SocketException {
      return false;
    } on IOException {
      return false;
    } catch (_) {
      return false;
    } finally {
      client.close(force: true);
    }
  }
}

class EnvConfigIssue {
  const EnvConfigIssue(this.message);
  final String message;
}

class EnvValidator {
  static EnvConfigIssue? validate() {
    final url = AppSecrets.supabaseUrl.trim();
    final key = AppSecrets.supabaseAnonKey.trim();

    if (url.isEmpty || key.isEmpty) {
      return const EnvConfigIssue(
        'Missing Supabase config. Add SUPABASE_URL and SUPABASE_ANON_KEY to your .env file.',
      );
    }

    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return const EnvConfigIssue(
        'SUPABASE_URL in .env is invalid. Use: https://YOUR_PROJECT.supabase.co',
      );
    }

    if (!uri.host.endsWith('supabase.co')) {
      return const EnvConfigIssue(
        'SUPABASE_URL must be your Supabase project URL (*.supabase.co).',
      );
    }

    // Legacy JWT anon keys are long; newer keys are still typically 80+ chars.
    if (key.length < 80) {
      return const EnvConfigIssue(
        'SUPABASE_ANON_KEY looks too short. Copy the full anon/public key from '
        'Supabase → Project Settings → API → Project API keys.',
      );
    }

    return null;
  }
}
