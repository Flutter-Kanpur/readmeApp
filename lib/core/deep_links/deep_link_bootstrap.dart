import 'dart:async';

import 'package:Readme/core/deep_links/deep_link_handler.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

/// Subscribes to cold-start and runtime app links.
class DeepLinkBootstrap {
  DeepLinkBootstrap._();

  static final AppLinks _appLinks = AppLinks();
  static StreamSubscription<Uri>? _linkSubscription;
  static Uri? _lastHandledUri;

  static Future<void> init() async {
    await _handleInitialLink();

    await _linkSubscription?.cancel();
    _linkSubscription = _appLinks.uriLinkStream.listen(
      _handleUri,
      onError: (Object error) {
        debugPrint('Deep link stream error: $error');
      },
    );
  }

  static Future<void> dispose() async {
    await _linkSubscription?.cancel();
    _linkSubscription = null;
  }

  static Future<void> _handleInitialLink() async {
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) {
        _handleUri(initial);
      }
    } catch (error) {
      debugPrint('Deep link initial URI error: $error');
    }
  }

  static void _handleUri(Uri uri) {
    if (_lastHandledUri == uri) return;
    _lastHandledUri = uri;
    DeepLinkHandler.navigate(uri);
  }
}
