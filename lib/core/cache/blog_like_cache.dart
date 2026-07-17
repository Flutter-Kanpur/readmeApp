import 'package:Readme/features/blog_detail/data/datasource/blog_like_datasource.dart';

/// Caches which blog IDs the current user has liked so list cards can avoid
/// one Supabase query per article.
class BlogLikeCache {
  BlogLikeCache._();

  static final BlogLikeCache instance = BlogLikeCache._();

  Map<String, bool>? _likedByBlogId;
  String? _userId;

  bool? isLiked(String blogId) => _likedByBlogId?[blogId];

  Future<void> preload({
    required String userId,
    required List<String> blogIds,
    required BlogLikeDatasource datasource,
  }) async {
    if (blogIds.isEmpty) {
      _likedByBlogId = const {};
      _userId = userId;
      return;
    }

    final likedIds = await datasource.fetchLikedBlogIds(
      userId: userId,
      blogIds: blogIds,
    );

    _userId = userId;
    _likedByBlogId = {
      for (final blogId in blogIds) blogId: likedIds.contains(blogId),
    };
  }

  void setLiked(String blogId, bool liked) {
    _likedByBlogId ??= {};
    _likedByBlogId![blogId] = liked;
  }

  void invalidate() {
    _likedByBlogId = null;
    _userId = null;
  }

  bool matchesUser(String userId) => _userId == userId;
}
