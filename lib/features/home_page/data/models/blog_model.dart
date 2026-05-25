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
    super.coauthors,
    super.imageUrls,
    super.communityId,
    super.communityName,
    super.communityLogoUrl,
  });

  factory BlogModel.fromJson(
    Map<String, dynamic> json, {
    List<String>? imageUrls,
  }) {
    final profile = json['profiles'];
    final community = json['communities'] as Map<String, dynamic>?;

    final primaryAuthor = Author(
      name: profile?['name'] ?? 'Unknown',
      avatarUrl: profile?['avatar_url'],
    );

    final coauthors = (json['blog_coauthors'] as List? ?? [])
        .map((entry) {
          final coProfile = entry['profiles'] as Map<String, dynamic>?;
          if (coProfile == null) return null;
          return Author(
            name: coProfile['name'] as String? ?? 'Unknown',
            avatarUrl: coProfile['avatar_url'] as String?,
          );
        })
        .whereType<Author>()
        .where((a) => a.name != primaryAuthor.name)
        .toList();

    return BlogModel(
      id: json['blog_id'],
      title: json['title'],
      content: normalizeRawContent(json['content']),
      coverImage: json['cover_image'],
      category: json['category'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      isPublished: json['is_published'] ?? false,
      imageUrls: imageUrls,
      communityId: json['community_id'] as String?,
      communityName: community?['name'] as String?,
      communityLogoUrl: community?['logo_url'] as String?,
      author: primaryAuthor,
      coauthors: coauthors,
    );
  }
}
