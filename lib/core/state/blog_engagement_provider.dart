import 'package:Readme/features/home_page/domain/entities/blog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Immutable engagement snapshot (likes/views) for a single blog.
class BlogEngagement {
  const BlogEngagement({required this.likeCount, required this.viewCount});

  final int likeCount;
  final int viewCount;

  BlogEngagement copyWith({int? likeCount, int? viewCount}) {
    return BlogEngagement(
      likeCount: likeCount ?? this.likeCount,
      viewCount: viewCount ?? this.viewCount,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is BlogEngagement &&
      other.likeCount == likeCount &&
      other.viewCount == viewCount;

  @override
  int get hashCode => Object.hash(likeCount, viewCount);
}

/// Session-scoped engagement counts shared across list and detail screens, so
/// they stay aligned without re-counting likes/views on every remount.
///
/// Replaces the former `BlogEngagementStore` `ChangeNotifier` singleton. State
/// is an immutable `Map<blogId, BlogEngagement>`; every mutation rebuilds the
/// map, and because [BlogEngagement] has value equality, `.select` watchers
/// rebuild only when *their* blog's counts actually change.
///
/// Monotonic guarantees (unchanged from the original store):
/// * [seed] / [seedAll] never *lower* an already-fresher local count.
/// * [applyViewCount] never decreases the view count.
/// * [applyLikeDelta] clamps the like count at `>= 0`.
class BlogEngagementNotifier extends Notifier<Map<String, BlogEngagement>> {
  @override
  Map<String, BlogEngagement> build() => const {};

  BlogEngagement? get(String blogId) => state[blogId];

  int likeCount(String blogId, {int fallback = 0}) =>
      state[blogId]?.likeCount ?? fallback;

  int viewCount(String blogId, {int fallback = 0}) =>
      state[blogId]?.viewCount ?? fallback;

  void seedEngagementFromBlog(Blog blog) {
    seed(blogId: blog.id, likeCount: blog.likeCount, viewCount: blog.viewCount);
  }

  void seedAll(Iterable<Blog> blogs) {
    final next = Map<String, BlogEngagement>.from(state);
    var changed = false;
    for (final blog in blogs) {
      final merged = _merge(next[blog.id], blog.likeCount, blog.viewCount);
      if (merged != null) {
        next[blog.id] = merged;
        changed = true;
      }
    }
    if (changed) state = next;
  }

  /// Seeds without lowering an already-fresher local count (e.g. after a
  /// like/view the local value can exceed the feed row).
  void seed({
    required String blogId,
    required int likeCount,
    required int viewCount,
  }) {
    final merged = _merge(state[blogId], likeCount, viewCount);
    if (merged != null) state = {...state, blogId: merged};
  }

  /// Returns the monotonically-merged value, or `null` if nothing changed.
  BlogEngagement? _merge(
    BlogEngagement? existing,
    int likeCount,
    int viewCount,
  ) {
    if (existing == null) {
      return BlogEngagement(
        likeCount: likeCount < 0 ? 0 : likeCount,
        viewCount: viewCount < 0 ? 0 : viewCount,
      );
    }
    final nextLikes =
        likeCount > existing.likeCount ? likeCount : existing.likeCount;
    final nextViews =
        viewCount > existing.viewCount ? viewCount : existing.viewCount;
    if (nextLikes == existing.likeCount && nextViews == existing.viewCount) {
      return null;
    }
    return BlogEngagement(likeCount: nextLikes, viewCount: nextViews);
  }

  void applyLikeDelta(String blogId, {required bool liked}) {
    final existing =
        state[blogId] ?? const BlogEngagement(likeCount: 0, viewCount: 0);
    final next = liked
        ? existing.likeCount + 1
        : (existing.likeCount - 1).clamp(0, 1 << 30);
    state = {...state, blogId: existing.copyWith(likeCount: next)};
  }

  void setLikeCount(String blogId, int likeCount) {
    final existing =
        state[blogId] ?? const BlogEngagement(likeCount: 0, viewCount: 0);
    final next = likeCount < 0 ? 0 : likeCount;
    if (existing.likeCount == next && state.containsKey(blogId)) return;
    state = {...state, blogId: existing.copyWith(likeCount: next)};
  }

  /// Prefer the freshest server/local value (never decrease after a view).
  void applyViewCount(String blogId, int viewCount) {
    final existing =
        state[blogId] ?? const BlogEngagement(likeCount: 0, viewCount: 0);
    final next = viewCount > existing.viewCount ? viewCount : existing.viewCount;
    if (existing.viewCount == next && state.containsKey(blogId)) return;
    state = {...state, blogId: existing.copyWith(viewCount: next)};
  }

  void invalidate() {
    if (state.isEmpty) return;
    state = const {};
  }
}

final blogEngagementProvider =
    NotifierProvider<BlogEngagementNotifier, Map<String, BlogEngagement>>(
      BlogEngagementNotifier.new,
    );
