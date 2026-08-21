import 'package:Readme/core/state/blog_engagement_provider.dart';
import 'package:Readme/features/home_page/domain/entities/blog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Unit tests for [BlogEngagementNotifier]'s monotonic semantics — the
/// guarantees that kept the old `BlogEngagementStore` from ever flickering a
/// count backwards when list and detail seeds raced.
void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() => container.dispose());

  BlogEngagementNotifier notifier() =>
      container.read(blogEngagementProvider.notifier);

  BlogEngagement engagement(String id) =>
      container.read(blogEngagementProvider)[id]!;

  Blog blog(String id, {int likeCount = 0, int viewCount = 0}) => Blog(
    id: id,
    title: 'Title $id',
    content: 'Body',
    category: 'general',
    createdAt: DateTime(2024, 1, 1),
    isPublished: true,
    author: const Author(id: 'author', name: 'Author'),
    likeCount: likeCount,
    viewCount: viewCount,
  );

  test('build() starts empty', () {
    expect(container.read(blogEngagementProvider), isEmpty);
  });

  test('seed inserts a new entry', () {
    notifier().seed(blogId: 'a', likeCount: 5, viewCount: 10);
    expect(engagement('a').likeCount, 5);
    expect(engagement('a').viewCount, 10);
  });

  test('seed never lowers an existing (fresher) count', () {
    notifier().seed(blogId: 'a', likeCount: 5, viewCount: 10);
    // A later, staler seed (e.g. from a list payload) must not regress.
    notifier().seed(blogId: 'a', likeCount: 2, viewCount: 3);
    expect(engagement('a').likeCount, 5);
    expect(engagement('a').viewCount, 10);
  });

  test('seed raises when the incoming count is higher', () {
    notifier().seed(blogId: 'a', likeCount: 5, viewCount: 10);
    notifier().seed(blogId: 'a', likeCount: 9, viewCount: 4);
    expect(engagement('a').likeCount, 9); // raised
    expect(engagement('a').viewCount, 10); // kept the fresher view count
  });

  test('seedAll clamps negatives to zero and seeds each blog', () {
    notifier().seedAll([
      blog('a', likeCount: 3, viewCount: 7),
      blog('b', likeCount: -1, viewCount: -4),
    ]);
    expect(engagement('a').likeCount, 3);
    expect(engagement('b').likeCount, 0);
    expect(engagement('b').viewCount, 0);
  });

  test('applyViewCount never decreases', () {
    notifier().seed(blogId: 'a', likeCount: 0, viewCount: 10);
    notifier().applyViewCount('a', 4); // stale, lower
    expect(engagement('a').viewCount, 10);
    notifier().applyViewCount('a', 20); // fresher, higher
    expect(engagement('a').viewCount, 20);
  });

  test('applyLikeDelta increments and clamps at zero', () {
    notifier().setLikeCount('a', 0);
    notifier().applyLikeDelta('a', liked: false); // cannot go below 0
    expect(engagement('a').likeCount, 0);
    notifier().applyLikeDelta('a', liked: true);
    expect(engagement('a').likeCount, 1);
    notifier().applyLikeDelta('a', liked: true);
    expect(engagement('a').likeCount, 2);
    notifier().applyLikeDelta('a', liked: false);
    expect(engagement('a').likeCount, 1);
  });

  test('setLikeCount clamps negatives to zero', () {
    notifier().setLikeCount('a', -5);
    expect(engagement('a').likeCount, 0);
    notifier().setLikeCount('a', 42);
    expect(engagement('a').likeCount, 42);
  });

  test('invalidate clears all entries', () {
    notifier().seed(blogId: 'a', likeCount: 5, viewCount: 10);
    notifier().seed(blogId: 'b', likeCount: 1, viewCount: 2);
    notifier().invalidate();
    expect(container.read(blogEngagementProvider), isEmpty);
  });

  test('mutations produce a new map instance so .select watchers rebuild', () {
    notifier().seed(blogId: 'a', likeCount: 1, viewCount: 1);
    final first = container.read(blogEngagementProvider);
    notifier().applyLikeDelta('a', liked: true);
    final second = container.read(blogEngagementProvider);
    expect(identical(first, second), isFalse);
  });
}
