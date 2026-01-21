import 'package:readme_blogapp/features/home_page/domain/entities/blog.dart';

abstract class BlogRepository {
  Future<List<Blog>> getBlogs();
}