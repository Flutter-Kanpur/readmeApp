import '../../domain/entities/blog.dart';
import '../../domain/repositories/blog_repository.dart';
import '../datasource/blog_remote_datasource.dart';

class BlogRepositoryImpl implements BlogRepository {
  final BlogRemoteDatasource remoteDatasource;

  BlogRepositoryImpl(this.remoteDatasource);

  @override
  Future<List<Blog>> getBlogs() async {
    return remoteDatasource.fetchBlogs();
  }

  @override
  Future<List<Blog>> getBlogsByAuthor(String authorId) async {
    return remoteDatasource.fetchBlogsByAuthor(authorId);
  }
}
