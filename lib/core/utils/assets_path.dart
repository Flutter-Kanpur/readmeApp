import 'package:Readme/core/config/readme_host.dart';
import 'package:flutter/services.dart';

/// Asset paths for the ReadMe package / standalone app.
///
/// When ReadMe is embedded in Flutter Kanpur, assets live under
/// `packages/Readme/assets/...` and loaders must pass [package].
/// When ReadMe is the host app, assets are registered as `assets/...`
/// and [package] must be null.
///
/// Call [AssetsPath.init] once at startup (before first asset load) so
/// [package] resolves correctly for either mode.
class AssetsPath {
  AssetsPath._();

  static const String packageName = 'Readme';

  /// `Readme` when bundled as a dependency; `null` when running standalone.
  static String? package = packageName;

  static bool _initialized = false;

  /// Detects whether assets are registered under `packages/Readme/...`.
  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final assets = manifest.listAssets();
      final asPackage = assets.contains('packages/$packageName/$googleIcon') ||
          assets.contains('packages/$packageName/$brandImage') ||
          assets.any((key) => key.startsWith('packages/$packageName/'));
      package = asPackage ? packageName : null;
      if (asPackage) {
        ReadmeHost.markEmbedded();
      }
    } catch (_) {
      // Prefer package asset paths if detection fails; do not flip host mode
      // here so the standalone app still shows logout / delete account.
      package = packageName;
    }
  }

  static const String home = 'assets/images/home.svg';
  static const String search = 'assets/images/search.svg';
  static const String create = 'assets/images/create.svg';
  static const String trending = 'assets/images/trending.svg';
  static const String profile = 'assets/images/profile.svg';
  static const String googleIcon = 'assets/icons/Google.svg';
  static const String phoneIcon = 'assets/icons/phone.svg';
  static const String draftIcon = 'assets/icons/draft.svg';
  static const String exploreIcon = 'assets/icons/explore.svg';
  static const String communityIcon = 'assets/icons/community.svg';
  static const String homeNaveIcon = 'assets/icons/home.svg';
  static const String profileNaveIcon = 'assets/icons/profile.svg';
  static const String brandImage = 'assets/images/image_5.png';
  static const String emptyLottie = 'assets/lottie/empty.json';
}
