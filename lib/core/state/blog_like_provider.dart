import 'package:Readme/core/providers/datasource_providers.dart';
import 'package:Readme/core/providers/supabase_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks which blog IDs the current user has liked, so list cards can avoid a
/// per-article Supabase query. Replaces the former `BlogLikeCache` singleton.
///
/// `build` watches the current user's id; when it changes (sign-in / sign-out /
/// account switch) the map resets automatically. This replaces the old manual
/// `_userId` / `matchesUser` scoping. Token refreshes for the *same* user do
/// not reset the map (we select on `u?.id`, not the whole `User`).
class BlogLikeNotifier extends Notifier<Map<String, bool>> {
  @override
  Map<String, bool> build() {
    ref.watch(currentUserProvider.select((user) => user?.id));
    return const {};
  }

  bool? isLiked(String blogId) => state[blogId];

  /// Batch-loads liked state for [blogIds] for the current user. Merges into
  /// any already-known entries rather than replacing them.
  Future<void> preload(List<String> blogIds) async {
    if (blogIds.isEmpty) return;
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final likedIds = await ref
        .read(blogLikeDatasourceProvider)
        .fetchLikedBlogIds(userId: user.id, blogIds: blogIds);

    state = {
      ...state,
      for (final blogId in blogIds) blogId: likedIds.contains(blogId),
    };
  }

  void setLiked(String blogId, bool liked) {
    state = {...state, blogId: liked};
  }
}

final blogLikeProvider = NotifierProvider<BlogLikeNotifier, Map<String, bool>>(
  BlogLikeNotifier.new,
);
