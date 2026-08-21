import 'package:Readme/core/providers/repository_providers.dart';
import 'package:Readme/core/state/blog_feed_provider.dart';
import 'package:Readme/features/home_page/domain/entities/blog.dart';
import 'package:Readme/features/home_page/domain/repositories/blog_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// A hand-written fake standing in for the real Supabase-backed
/// [BlogRepository]. It proves the DI payoff of the migration: [blogFeedProvider]
/// can be driven entirely from an override, with no client/network involved.
class _FakeBlogRepository implements BlogRepository {
  _FakeBlogRepository(this._blogs);

  List<Blog> _blogs;
  int getBlogsCalls = 0;

  void setBlogs(List<Blog> blogs) => _blogs = blogs;

  @override
  Future<List<Blog>> getBlogs() async {
    getBlogsCalls++;
    return _blogs;
  }

  @override
  Future<List<Blog>> getBlogsByAuthor(String authorId) async =>
      _blogs.where((b) => b.author.id == authorId).toList();

  @override
  Future<Blog?> getBlogById(String blogId) async {
    for (final b in _blogs) {
      if (b.id == blogId) return b;
    }
    return null;
  }
}

Blog _blog(String id, {String? title}) => Blog(
  id: id,
  title: title ?? 'Title $id',
  content: 'Body',
  category: 'general',
  createdAt: DateTime(2024, 1, 1),
  isPublished: true,
  author: const Author(id: 'author', name: 'Author'),
);

void main() {
  test('blogFeedProvider loads blogs from the overridden repository', () async {
    final fake = _FakeBlogRepository([_blog('1'), _blog('2')]);
    final container = ProviderContainer(
      overrides: [blogRepositoryProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);

    final blogs = await container.read(blogFeedProvider.future);

    expect(blogs.map((b) => b.id), ['1', '2']);
    expect(fake.getBlogsCalls, 1);
  });

  test('refresh() re-fetches through the repository', () async {
    final fake = _FakeBlogRepository([_blog('1')]);
    final container = ProviderContainer(
      overrides: [blogRepositoryProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);

    await container.read(blogFeedProvider.future);
    expect(fake.getBlogsCalls, 1);

    fake.setBlogs([_blog('1'), _blog('2')]);
    await container.read(blogFeedProvider.notifier).refresh();

    final blogs = container.read(blogFeedProvider).value;
    expect(blogs, isNotNull);
    expect(blogs!.length, 2);
    expect(fake.getBlogsCalls, 2);
  });

  testWidgets('a ConsumerWidget renders feed titles from the overridden repo', (
    tester,
  ) async {
    final fake = _FakeBlogRepository([
      _blog('1', title: 'Alpha'),
      _blog('2', title: 'Beta'),
    ]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [blogRepositoryProvider.overrideWithValue(fake)],
        child: const MaterialApp(home: _FeedProbe()),
      ),
    );

    // No spinner widget is used while loading, so pumpAndSettle is safe.
    await tester.pumpAndSettle();

    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Beta'), findsOneWidget);
  });
}

/// Minimal widget that reads [blogFeedProvider] the same way the real screens
/// do (value-with-previous), used to assert the override reaches the UI layer.
class _FeedProbe extends ConsumerWidget {
  const _FeedProbe();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blogs = ref.watch(blogFeedProvider).value;
    if (blogs == null) return const SizedBox();
    return Scaffold(
      body: Column(children: [for (final b in blogs) Text(b.title)]),
    );
  }
}
