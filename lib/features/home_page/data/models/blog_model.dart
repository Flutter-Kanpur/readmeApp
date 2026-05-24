import '../../domain/entities/blog.dart';
import '../../../../core/utils/quill_content_parser.dart';

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
    super.imageUrls,
  });

  factory BlogModel.fromJson(
    Map<String, dynamic> json, {
    List<String>? imageUrls,
  }) {
    final profile = json['profiles'];

    return BlogModel(
      id: json['blog_id'],
      title: json['title'],
      content: normalizeRawContent(json['content']),
      coverImage: json['cover_image'],
      category: json['category'],
      createdAt: DateTime.parse(json['created_at']),
      isPublished: json['is_published'] ?? false,
      imageUrls: imageUrls,
      author: Author(
        name: profile?['name'] ?? 'Unknown',
        avatarUrl: profile?['avatar_url'],
      ),
    );
  }
}
