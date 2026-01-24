import '../../domain/entities/blog.dart';

class BlogModel extends Blog {
  const BlogModel({
    required super.id,
    required super.title,
    required super.content,
    super.coverImage,
    required super.category,
    required super.createdAt,
    required super.isPublished,
    required super.author,
  });

  factory BlogModel.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'];

    return BlogModel(
      id: json['blog_id'],
      title: json['title'],
      content: json['content'],
      coverImage: json['cover_image'],
      category: json['category'],
      createdAt: DateTime.parse(json['created_at']),
      isPublished: json['is_published'] ?? false,
      author: Author(
        name: profile?['name'] ?? 'Unknown',
        avatarUrl: profile?['avatar_url'],
      ),
    );
  }
}
