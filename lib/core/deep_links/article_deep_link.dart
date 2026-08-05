/// Parses shared article URLs into in-app `/blog/:id` routes.
class ArticleDeepLink {
  ArticleDeepLink._();

  static const String linkHost = 'readme.flutterkanpur.in';

  static final RegExp _articlePathPattern = RegExp(r'/articles/([^/?#]+)');

  /// Returns the blog id when [uri] is a supported article link.
  static String? parseBlogId(Uri uri) {
    if (uri.host.isNotEmpty && uri.host != linkHost) return null;
    return _articlePathPattern.firstMatch(uri.path)?.group(1);
  }

  /// In-app route for [uri], or null when not an article link.
  static String? routeFor(Uri uri) {
    final blogId = parseBlogId(uri);
    if (blogId == null || blogId.isEmpty) return null;
    return '/blog/$blogId';
  }
}
