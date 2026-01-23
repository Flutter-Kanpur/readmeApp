import '../../domain/entities/blog.dart';

List<String> extractCategories(List<Blog> blogs) {
  return blogs
      .map((blog) => blog.category)
      .where((c) => c.isNotEmpty)
      .toSet() // DISTINCT
      .toList();
}
