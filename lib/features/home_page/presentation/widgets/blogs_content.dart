import 'package:flutter/material.dart';
import '../../domain/entities/blog.dart';
import '../../domain/repositories/blog_repository.dart';
import 'blog_card.dart';

class BlogsContent extends StatelessWidget {
  final String category;
  final BlogRepository blogRepository;

  const BlogsContent({
    super.key,
    required this.category,
    required this.blogRepository,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Blog>>(
      future: blogRepository.getBlogs(),
      builder: (context, snapshot) {
        // 1️⃣ Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // 2️⃣ Error state
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final allBlogs = snapshot.data ?? [];

        // 🔍 DEBUG (remove later)
        debugPrint('Fetched blogs count: ${allBlogs.length}');
        for (final blog in allBlogs) {
          debugPrint('Blog category: ${blog.category}');
        }

        // 3️⃣ Safe category filtering
        final blogs = allBlogs.where((b) {
          return b.category.trim().toLowerCase() ==
              category.trim().toLowerCase();
        }).toList();

        // 4️⃣ Empty state
        if (blogs.isEmpty) {
          return const Center(
            child: Text(
              'No blogs found',
              style: TextStyle(fontSize: 14),
            ),
          );
        }

        // 5️⃣ Success state
        return ListView.builder(
          itemCount: blogs.length,
          itemBuilder: (context, index) {
            return BlogCard(blog: blogs[index]);
          },
        );
      },
    );
  }
}
