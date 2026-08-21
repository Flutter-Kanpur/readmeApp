import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase-backed reads and writes for the blog composer.
///
/// Every `blogs`/`profiles`/storage call that used to live inline in
/// `create_blog_screen.dart` is centralised here so the screen depends only on
/// [CreateBlogRepository] and never touches the client directly.
class CreateBlogRemoteDatasource {
  CreateBlogRemoteDatasource(this.client);

  final SupabaseClient client;

  /// Loads the editable fields of an existing post owned by [userId], or `null`
  /// if it doesn't exist / isn't theirs.
  Future<Map<String, dynamic>?> fetchEditableBlog({
    required String blogId,
    required String userId,
  }) async {
    return client
        .from('blogs')
        .select('title, content, category, tags, cover_image')
        .eq('blog_id', blogId)
        .eq('author_id', userId)
        .maybeSingle();
  }

  /// The author's full profile row (all columns), used to render the byline.
  Future<Map<String, dynamic>?> fetchAuthorProfile(String userId) async {
    return client.from('profiles').select().eq('id', userId).maybeSingle();
  }

  /// Uploads [bytes] to the `blog_images` bucket at [fileName] and returns the
  /// public URL. [fileName] carries the folder prefix (`covers/…`, `blogs/…`).
  Future<String> uploadImage({
    required String fileName,
    required Uint8List bytes,
  }) async {
    await client.storage.from('blog_images').uploadBinary(fileName, bytes);
    return client.storage.from('blog_images').getPublicUrl(fileName);
  }

  /// Updates the post when [blogId] is set, otherwise inserts a new one; either
  /// way returns the effective `blog_id`. [payload] already carries
  /// `is_published` and (when publishing) `published_at`.
  Future<String> upsertBlog({
    required String userId,
    String? blogId,
    required Map<String, dynamic> payload,
  }) async {
    if (blogId != null) {
      await client
          .from('blogs')
          .update(payload)
          .eq('blog_id', blogId)
          .eq('author_id', userId);
      return blogId;
    }

    final row = await client
        .from('blogs')
        .insert({...payload, 'author_id': userId})
        .select('blog_id')
        .single();
    return row['blog_id'] as String;
  }
}
