import 'package:flutter/material.dart';
import 'package:Readme/features/home_page/domain/entities/blog.dart';
import 'package:Readme/features/home_page/presentation/widgets/blog_card.dart';

class BlogsContent extends StatelessWidget {
  final List<Blog> blogs;

  const BlogsContent({
    super.key,
    required this.blogs,
  });

  @override
  Widget build(BuildContext context) {
    if (blogs.isEmpty) {
      return const Center(
        child: Text(
          'No blogs found',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: blogs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final blog = blogs[index];
        return BlogCard(
          blog: blog,
        );
      },
    );
  }
}
