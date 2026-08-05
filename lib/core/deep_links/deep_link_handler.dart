import 'package:Readme/core/deep_links/article_deep_link.dart';
import 'package:Readme/core/router/routes.dart';

/// Routes HTTPS article links into the app.
class DeepLinkHandler {
  DeepLinkHandler._();

  /// Navigates to `/blog/:id` when [uri] matches a supported article link.
  static bool navigate(Uri uri) {
    final route = ArticleDeepLink.routeFor(uri);
    if (route == null) return false;

    AppRouter.router.go(route);
    return true;
  }
}
