import 'package:supabase_flutter/supabase_flutter.dart';

class BlogLikeDatasource {
  BlogLikeDatasource(this.client);

  final SupabaseClient client;

  Future<int> fetchLikeCount(String blogId) async {
    try {
      final count = await client
          .from('blog_likes')
          .count(CountOption.exact)
          .eq('blog_id', blogId);
      return count;
    } catch (_) {
      return 0;
    }
  }

  Future<bool> isLikedByUser({
    required String blogId,
    required String userId,
  }) async {
    try {
      final response = await client
          .from('blog_likes')
          .select('id')
          .eq('blog_id', blogId)
          .eq('user_id', userId)
          .maybeSingle();
      return response != null;
    } catch (_) {
      return false;
    }
  }

  Future<Set<String>> fetchLikedBlogIds({
    required String userId,
    required List<String> blogIds,
  }) async {
    if (blogIds.isEmpty) return {};

    try {
      final response = await client
          .from('blog_likes')
          .select('blog_id')
          .eq('user_id', userId)
          .inFilter('blog_id', blogIds);

      return (response as List).map((row) => row['blog_id'] as String).toSet();
    } catch (_) {
      return {};
    }
  }

  Future<void> likeBlog({
    required String blogId,
    required String userId,
  }) async {
    try {
      await client.from('blog_likes').insert({
        'blog_id': blogId,
        'user_id': userId,
      });
    } on PostgrestException catch (e) {
      if (e.code == '23505') return;
      rethrow;
    }
  }

  Future<void> unlikeBlog({
    required String blogId,
    required String userId,
  }) async {
    await client
        .from('blog_likes')
        .delete()
        .eq('blog_id', blogId)
        .eq('user_id', userId);
  }
}
