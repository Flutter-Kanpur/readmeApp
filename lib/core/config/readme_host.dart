import 'package:Readme/core/network/readme_supabase.dart';

/// Host / embedding mode for ReadMe.
///
/// Standalone Play Store app: [isEmbedded] stays `false` (no [ReadmeSupabase.bind]).
/// Flutter Kanpur: calls [ReadmeSupabase.bind] → treated as embedded.
class ReadmeHost {
  ReadmeHost._();

  static bool _embedded = false;

  /// True when ReadMe is opened inside Flutter Kanpur (or another host app).
  static bool get isEmbedded => _embedded || ReadmeSupabase.isBound;

  /// Logout / delete-account / app version are only for the standalone app.
  static bool get showAccountLifecycleActions => !isEmbedded;

  /// Call from the host when mounting ReadMe (optional if using [ReadmeSupabase.bind]).
  static void configure({required bool embedded}) {
    _embedded = embedded;
  }

  static void markEmbedded() {
    _embedded = true;
  }
}
