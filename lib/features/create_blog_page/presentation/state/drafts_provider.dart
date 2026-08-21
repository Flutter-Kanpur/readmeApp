import 'package:Readme/core/providers/datasource_providers.dart';
import 'package:Readme/core/providers/supabase_providers.dart';
import 'package:Readme/core/state/blog_feed_provider.dart';
import 'package:Readme/core/utils/draft_storage.dart';
import 'package:Readme/features/create_blog_page/domain/entities/blog_draft.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The signed-in user's drafts (remote unpublished posts + any on-device draft).
///
/// Replaces `my_drafts_screen`'s manual `onAuthStateChange` subscription: [build]
/// watches [currentUserProvider], so the list reloads on sign-in / sign-out and
/// clears to empty when signed out. Publishing invalidates [blogFeedProvider] so
/// the freshly-published post shows up on Home/Search.
class DraftsNotifier extends AsyncNotifier<List<BlogDraft>> {
  Future<List<BlogDraft>> _load() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return const [];
    return ref.read(blogDraftDatasourceProvider).fetchAllDrafts(user.id);
  }

  @override
  Future<List<BlogDraft>> build() {
    ref.watch(currentUserProvider); // reload when the signed-in user changes
    return _load();
  }

  /// Re-fetches the list (pull-to-refresh, tab re-entry, post-edit return).
  Future<void> refresh() async {
    state = const AsyncValue<List<BlogDraft>>.loading();
    state = await AsyncValue.guard(_load);
  }

  /// Publishes a remote draft, refreshes the feed, then reloads the list.
  Future<void> publish(String blogId) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    await ref
        .read(blogDraftDatasourceProvider)
        .publishDraft(blogId: blogId, userId: user.id);
    ref.invalidate(blogFeedProvider);
    await refresh();
  }

  /// Permanently deletes a remote draft, then reloads the list.
  Future<void> delete(String blogId) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    await ref
        .read(blogDraftDatasourceProvider)
        .deleteDraft(blogId: blogId, userId: user.id);
    await refresh();
  }

  /// Clears the on-device draft, then reloads the list.
  Future<void> clearLocalDraft() async {
    await DraftStorage.clearDraft();
    await refresh();
  }
}

final draftsProvider = AsyncNotifierProvider<DraftsNotifier, List<BlogDraft>>(
  DraftsNotifier.new,
);
