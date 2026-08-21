import 'dart:typed_data';

import 'package:Readme/features/create_blog_page/data/datasource/create_blog_remote_datasource.dart';
import 'package:Readme/features/create_blog_page/domain/repositories/create_blog_repository.dart';

/// Thin Supabase-backed implementation; delegates to
/// [CreateBlogRemoteDatasource] and passes the raw row maps straight through.
class CreateBlogRepositoryImpl implements CreateBlogRepository {
  CreateBlogRepositoryImpl(this._remote);

  final CreateBlogRemoteDatasource _remote;

  @override
  Future<Map<String, dynamic>?> loadEditableBlog({
    required String blogId,
    required String userId,
  }) {
    return _remote.fetchEditableBlog(blogId: blogId, userId: userId);
  }

  @override
  Future<Map<String, dynamic>?> loadAuthorProfile(String userId) {
    return _remote.fetchAuthorProfile(userId);
  }

  @override
  Future<String> uploadImage({
    required String fileName,
    required Uint8List bytes,
  }) {
    return _remote.uploadImage(fileName: fileName, bytes: bytes);
  }

  @override
  Future<String> saveBlog({
    required String userId,
    String? blogId,
    required Map<String, dynamic> payload,
  }) {
    return _remote.upsertBlog(userId: userId, blogId: blogId, payload: payload);
  }
}
