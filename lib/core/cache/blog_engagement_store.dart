import 'package:Readme/features/home_page/domain/entities/blog.dart';
import 'package:flutter/foundation.dart';

class BlogEngagement {
  const BlogEngagement({
    required this.likeCount,
    required this.viewCount,
  });

  final int likeCount;
  final int viewCount;

  BlogEngagement copyWith({int? likeCount, int? viewCount}) {
    return BlogEngagement(
      likeCount: likeCount ?? this.likeCount,
      viewCount: viewCount ?? this.viewCount,
    );
  }
}

/// Session-scoped engagement counts so list and detail stay aligned without
/// re-counting likes/views on every remount.
class BlogEngagementStore extends ChangeNotifier {
  BlogEngagementStore._();

  static final BlogEngagementStore instance = BlogEngagementStore._();

  final Map<String, BlogEngagement> _byBlogId = {};

  BlogEngagement? get(String blogId) => _byBlogId[blogId];

  int likeCount(String blogId, {int fallback = 0}) =>
      _byBlogId[blogId]?.likeCount ?? fallback;

  int viewCount(String blogId, {int fallback = 0}) =>
      _byBlogId[blogId]?.viewCount ?? fallback;

  void seedEngagementFromBlog(Blog blog) {
    seed(
      blogId: blog.id,
      likeCount: blog.likeCount,
      viewCount: blog.viewCount,
    );
  }

  void seedAll(Iterable<Blog> blogs) {
    var changed = false;
    for (final blog in blogs) {
      if (_seedInternal(
        blogId: blog.id,
        likeCount: blog.likeCount,
        viewCount: blog.viewCount,
      )) {
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  /// Seeds without lowering an already-fresher local count (e.g. after like/view).
  void seed({
    required String blogId,
    required int likeCount,
    required int viewCount,
  }) {
    if (_seedInternal(
      blogId: blogId,
      likeCount: likeCount,
      viewCount: viewCount,
    )) {
      notifyListeners();
    }
  }

  bool _seedInternal({
    required String blogId,
    required int likeCount,
    required int viewCount,
  }) {
    final existing = _byBlogId[blogId];
    if (existing == null) {
      _byBlogId[blogId] = BlogEngagement(
        likeCount: likeCount < 0 ? 0 : likeCount,
        viewCount: viewCount < 0 ? 0 : viewCount,
      );
      return true;
    }

    final nextLikes = likeCount > existing.likeCount
        ? likeCount
        : existing.likeCount;
    final nextViews = viewCount > existing.viewCount
        ? viewCount
        : existing.viewCount;
    if (nextLikes == existing.likeCount && nextViews == existing.viewCount) {
      return false;
    }
    _byBlogId[blogId] = BlogEngagement(
      likeCount: nextLikes,
      viewCount: nextViews,
    );
    return true;
  }

  void applyLikeDelta(String blogId, {required bool liked}) {
    final existing = _byBlogId[blogId] ??
        const BlogEngagement(likeCount: 0, viewCount: 0);
    final next = liked
        ? existing.likeCount + 1
        : (existing.likeCount - 1).clamp(0, 1 << 30);
    _byBlogId[blogId] = existing.copyWith(likeCount: next);
    notifyListeners();
  }

  void setLikeCount(String blogId, int likeCount) {
    final existing = _byBlogId[blogId] ??
        const BlogEngagement(likeCount: 0, viewCount: 0);
    final next = likeCount < 0 ? 0 : likeCount;
    if (existing.likeCount == next && _byBlogId.containsKey(blogId)) {
      return;
    }
    _byBlogId[blogId] = existing.copyWith(likeCount: next);
    notifyListeners();
  }

  /// Prefer the freshest server/local value (never decrease after a view).
  void applyViewCount(String blogId, int viewCount) {
    final existing = _byBlogId[blogId] ??
        const BlogEngagement(likeCount: 0, viewCount: 0);
    final next = viewCount > existing.viewCount ? viewCount : existing.viewCount;
    if (existing.viewCount == next && _byBlogId.containsKey(blogId)) {
      return;
    }
    _byBlogId[blogId] = existing.copyWith(viewCount: next);
    notifyListeners();
  }

  void invalidate() {
    if (_byBlogId.isEmpty) return;
    _byBlogId.clear();
    notifyListeners();
  }
}
