import 'dart:typed_data';

/// The blog-composer's data contract. The screen depends on this interface;
/// [CreateBlogRepositoryImpl] wires it to Supabase.
abstract class CreateBlogRepository {
  /// Editable fields of an existing post owned by [userId], or `null`.
  Future<Map<String, dynamic>?> loadEditableBlog({
    required String blogId,
    required String userId,
  });

  /// The author's profile row, used for the byline. `null` when absent.
  Future<Map<String, dynamic>?> loadAuthorProfile(String userId);

  /// Uploads [bytes] under [fileName] (prefix included) and returns its URL.
  Future<String> uploadImage({
    required String fileName,
    required Uint8List bytes,
  });

  /// Saves the post (update when [blogId] is set, else insert) and returns the
  /// effective `blog_id`.
  Future<String> saveBlog({
    required String userId,
    String? blogId,
    required Map<String, dynamic> payload,
  });
}
