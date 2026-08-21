import 'package:Readme/core/providers/repository_providers.dart';
import 'package:Readme/features/home_page/domain/entities/blog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shared published-blog feed for Home and Search.
///
/// Non-autoDispose so both screens read a single cached instance and never
/// duplicate the Supabase query (the former `BlogFeedCache` did this with a
/// singleton + in-flight dedup; here it is inherent to the provider). The
/// 5-minute TTL is preserved via [refreshIfStale]; the old `invalidate()` calls
/// become `ref.invalidate(blogFeedProvider)`.
class BlogFeedNotifier extends AsyncNotifier<List<Blog>> {
  static const _ttl = Duration(minutes: 5);
  DateTime? _fetchedAt;

  @override
  Future<List<Blog>> build() => _fetch();

  Future<List<Blog>> _fetch() async {
    final blogs = await ref.read(blogRepositoryProvider).getBlogs();
    _fetchedAt = DateTime.now();
    return blogs;
  }

  bool get _isStale {
    final at = _fetchedAt;
    return at == null || DateTime.now().difference(at) >= _ttl;
  }

  /// Re-fetches only when the cached feed is older than the TTL. Call on screen
  /// entry; no-op while a load is already in flight.
  Future<void> refreshIfStale() async {
    if (state.isLoading) return;
    if (_isStale) await refresh();
  }

  /// Forces a re-fetch regardless of TTL (pull-to-refresh).
  Future<void> refresh() async {
    state = const AsyncValue<List<Blog>>.loading();
    state = await AsyncValue.guard(_fetch);
  }
}

final blogFeedProvider = AsyncNotifierProvider<BlogFeedNotifier, List<Blog>>(
  BlogFeedNotifier.new,
);
