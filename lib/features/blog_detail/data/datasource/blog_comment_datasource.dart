import 'package:Readme/features/blog_detail/data/models/blog_comment_model.dart';
import 'package:Readme/features/blog_detail/domain/entities/blog_comment.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BlogCommentDatasource {
  BlogCommentDatasource(this.client);

  final SupabaseClient client;

  static const _select = '''
      id,
      blog_id,
      user_id,
      parent_id,
      body,
      like_count,
      created_at,
      profiles!blog_comments_user_id_fkey (
        id,
        name,
        avatar_url
      )
    ''';

  Future<List<BlogComment>> fetchComments(String blogId) async {
    final response = await client
        .from('blog_comments')
        .select(_select)
        .eq('blog_id', blogId)
        .order('created_at', ascending: true);

    final rows = (response as List)
        .map((row) => BlogCommentModel.fromJson(Map<String, dynamic>.from(row)))
        .toList();

    final topLevel = <BlogComment>[];
    final repliesByParent = <String, List<BlogComment>>{};

    for (final comment in rows) {
      if (comment.parentId == null) {
        topLevel.add(comment);
      } else {
        repliesByParent
            .putIfAbsent(comment.parentId!, () => [])
            .add(comment);
      }
    }

    return topLevel
        .map(
          (comment) => comment.copyWith(
            replies: repliesByParent[comment.id] ?? const [],
          ),
        )
        .toList();
  }

  Future<BlogComment> postComment({
    required String blogId,
    required String userId,
    required String body,
  }) async {
    final response = await client
        .from('blog_comments')
        .insert({
          'blog_id': blogId,
          'user_id': userId,
          'body': body.trim(),
        })
        .select(_select)
        .single();

    return BlogCommentModel.fromJson(Map<String, dynamic>.from(response));
  }

  Future<BlogComment> postReply({
    required String blogId,
    required String parentId,
    required String userId,
    required String body,
  }) async {
    final response = await client
        .from('blog_comments')
        .insert({
          'blog_id': blogId,
          'parent_id': parentId,
          'user_id': userId,
          'body': body.trim(),
        })
        .select(_select)
        .single();

    return BlogCommentModel.fromJson(Map<String, dynamic>.from(response));
  }

  Future<Set<String>> fetchLikedCommentIds({
    required String userId,
    required List<String> commentIds,
  }) async {
    if (commentIds.isEmpty) return {};

    final response = await client
        .from('blog_comment_likes')
        .select('comment_id')
        .eq('user_id', userId)
        .inFilter('comment_id', commentIds);

    return (response as List)
        .map((row) => row['comment_id'] as String)
        .toSet();
  }

  Future<void> likeComment({
    required String commentId,
    required String userId,
  }) async {
    try {
      await client.from('blog_comment_likes').insert({
        'comment_id': commentId,
        'user_id': userId,
      });
    } on PostgrestException catch (e) {
      if (e.code == '23505') return;
      rethrow;
    }
  }

  Future<void> unlikeComment({
    required String commentId,
    required String userId,
  }) async {
    await client
        .from('blog_comment_likes')
        .delete()
        .eq('comment_id', commentId)
        .eq('user_id', userId);
  }
}
