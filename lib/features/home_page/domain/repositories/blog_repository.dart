import 'package:Readme/features/home_page/domain/entities/blog.dart';

abstract class BlogRepository {
  Future<List<Blog>> getBlogs();
  Future<List<Blog>> getBlogsByAuthor(String authorId);
}