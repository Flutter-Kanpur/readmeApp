import '../models/blog_model.dart';
import '../../domain/entities/blog.dart';

final List<BlogModel> dummyBlogs = [
  BlogModel(
    id: 'dummy-1',
    title: 'Welcome to Readme',
    content: 'Start exploring amazing blogs curated just for you.',
    coverImage: null,
    category: 'for_you',
    createdAt: DateTime.now(),
    isPublished: true,
    author: const Author(
      name: 'Readme Team',
      avatarUrl: null,
    ),
  ),
];
