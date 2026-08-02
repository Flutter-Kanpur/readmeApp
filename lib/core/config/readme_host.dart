/// Host / embedding mode for ReadMe.
///
/// Standalone Play Store app: [isEmbedded] stays `false`.
/// Flutter Kanpur (or any host): set via [ReadmeSupabase.bind] or
/// [configure], or detected when assets load under `packages/Readme/`.
class ReadmeHost {
  ReadmeHost._();

  static bool _embedded = false;

  /// True when ReadMe is opened inside Flutter Kanpur (or another host app).
  static bool get isEmbedded => _embedded;

  /// Logout / delete-account are only for the standalone ReadMe app.
  static bool get showAccountLifecycleActions => !_embedded;

  /// Call from the host when mounting ReadMe (optional if using [ReadmeSupabase.bind]).
  static void configure({required bool embedded}) {
    _embedded = embedded;
  }

  static void markEmbedded() {
    _embedded = true;
  }
}
