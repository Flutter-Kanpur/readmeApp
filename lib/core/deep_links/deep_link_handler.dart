import 'package:Readme/core/router/routes.dart';

/// Parses and routes HTTPS article links into the app.
class DeepLinkHandler {
  DeepLinkHandler._();

  static const String linkHost = 'readme.flutterkanpur.in';

  static final RegExp _articlePathPattern = RegExp(r'/articles/([^/?#]+)');

  /// Returns the blog id when [uri] is a supported article link.
  static String? parseBlogId(Uri uri) {
    if (uri.host != linkHost) return null;
    final match = _articlePathPattern.firstMatch(uri.path);
    return match?.group(1);
  }

  /// Navigates to `/blog/:id` when [uri] matches a supported article link.
  static bool navigate(Uri uri) {
    final blogId = parseBlogId(uri);
    if (blogId == null || blogId.isEmpty) return false;

    AppRouter.router.go('/blog/$blogId');
    return true;
  }
}
