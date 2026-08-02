import 'package:Readme/core/config/readme_host.dart';
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

  /// True after [bind] — ReadMe is running inside a host app.
  static bool get isBound => _override != null;

  /// Bind a host-provided Supabase client and mark ReadMe as embedded
  /// (hides standalone-only account actions like logout / delete).
  static void bind(SupabaseClient client) {
    _override = client;
    ReadmeHost.markEmbedded();
  }

  static void clear() {
    _override = null;
  }
}
