import 'package:supabase_flutter/supabase_flutter.dart';

/// Backend client for ReadMe blog features.
///
/// Standalone ReadMe app: falls back to [Supabase.instance.client].
/// Host apps (Flutter Kanpur): call [bind] with a client pointed at the
/// ReadMe Supabase project so blogs don't query the host database.
class ReadmeSupabase {
  ReadmeSupabase._();

  static SupabaseClient? _override;

  static SupabaseClient get client => _override ?? Supabase.instance.client;

  static void bind(SupabaseClient client) {
    _override = client;
  }

  static void clear() {
    _override = null;
  }
}
