import 'package:Readme/core/utils/draft_storage.dart';
import 'package:Readme/core/utils/quill_content_parser.dart';
import 'package:Readme/features/create_blog_page/domain/entities/blog_draft.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BlogDraftDatasource {
  BlogDraftDatasource(this.client);

  final SupabaseClient client;

  /// Loads Supabase drafts plus any unsynced local editor draft.
  Future<List<BlogDraft>> fetchAllDrafts(String userId) async {
    final remote = await fetchMyDrafts(userId);
    final local = await _localDraftIfAny();
    if (local == null) return remote;

    // Hide local placeholder when the same draft was already saved remotely.
    final hasMatchingRemote = remote.any(
      (draft) =>
          draft.title.trim().toLowerCase() ==
              local.title.trim().toLowerCase() &&
          draft.title.trim().isNotEmpty,
    );
    if (hasMatchingRemote) return remote;

    return [local, ...remote];
  }

  Future<List<BlogDraft>> fetchMyDrafts(String userId) async {
    final rows = await client
        .from('blogs')
        .select('blog_id, title, content, category, created_at')
        .eq('author_id', userId)
        .or('is_published.eq.false,is_published.is.null')
        .order('created_at', ascending: false);

    return (rows as List)
        .map((row) => _fromRow(row as Map<String, dynamic>))
        .toList();
  }

  Future<void> publishDraft({
    required String blogId,
    required String userId,
  }) async {
    await client
        .from('blogs')
        .update({
          'is_published': true,
          'published_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('blog_id', blogId)
        .eq('author_id', userId);
  }

  Future<void> deleteDraft({
    required String blogId,
    required String userId,
  }) async {
    await client
        .from('blogs')
        .delete()
        .eq('blog_id', blogId)
        .eq('author_id', userId);
  }

  Future<BlogDraft?> _localDraftIfAny() async {
    final entry = await DraftStorage.getDraft();
    if (entry == null || entry.isEmpty) return null;

    return BlogDraft(
      id: BlogDraft.localDraftId,
      title: entry.title,
      content: entry.content,
      category: 'Technology',
      updatedAt: entry.savedAt ?? DateTime.now(),
      isLocalOnly: true,
    );
  }

  BlogDraft _fromRow(Map<String, dynamic> row) {
    final updatedAtRaw = row['created_at'] as String?;
    return BlogDraft(
      id: row['blog_id'] as String,
      title: (row['title'] as String?)?.trim() ?? '',
      content: normalizeRawContent(row['content']),
      category: (row['category'] as String?)?.trim().isNotEmpty == true
          ? row['category'] as String
          : 'Uncategorized',
      updatedAt: updatedAtRaw != null
          ? DateTime.parse(updatedAtRaw)
          : DateTime.now(),
    );
  }
}
