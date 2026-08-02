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
    super.publishedAt,
    required super.isPublished,
    required super.author,
    super.coauthors,
    super.imageUrls,
    super.communityId,
    super.communityName,
    super.communityLogoUrl,
    super.likeCount,
    super.viewCount,
  });

  factory BlogModel.fromJson(
    Map<String, dynamic> json, {
    List<String>? imageUrls,
  }) {
    final authorId = json['author_id'] as String?;
    final profile = json['profiles'];
    final profileId = profile?['id'] as String?;
    final community = json['communities'] as Map<String, dynamic>?;
    final createdAt = DateTime.parse(json['created_at'] as String);

    final primaryAuthor = Author(
      id: authorId ?? profileId,
      name: profile?['name'] ?? 'Unknown',
      avatarUrl: profile?['avatar_url'],
    );

    final coauthors = (json['blog_coauthors'] as List? ?? [])
        .map((entry) {
          final coProfile = entry['profiles'] as Map<String, dynamic>?;
          if (coProfile == null) return null;
          return Author(
            id: entry['user_id'] as String? ?? coProfile['id'] as String?,
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
      content: json['content'] == null
          ? ''
          : normalizeRawContent(json['content']),
      coverImage: json['cover_image'],
      category: json['category'] ?? '',
      createdAt: createdAt,
      publishedAt: _parsePublishedAt(json, createdAt),
      isPublished: json['is_published'] ?? false,
      imageUrls: imageUrls,
      communityId: json['community_id'] as String?,
      communityName: community?['name'] as String?,
      communityLogoUrl: community?['logo_url'] as String?,
      author: primaryAuthor,
      coauthors: coauthors,
      likeCount: _parseLikeCount(json),
      viewCount: _parseViewCount(json),
    );
  }

  static DateTime? _parsePublishedAt(
    Map<String, dynamic> json,
    DateTime createdAt,
  ) {
    final raw = json['published_at'];
    if (raw is String && raw.isNotEmpty) {
      return DateTime.tryParse(raw);
    }
    // Fallback while older rows / clients lack the column.
    if (json['is_published'] == true) return createdAt;
    return null;
  }

  static int _parseLikeCount(Map<String, dynamic> json) {
    final direct = json['like_count'];
    if (direct is int) return direct;
    if (direct is num) return direct.toInt();

    // Rollout fallback if denormalized column is not selected yet.
    final likes = json['blog_likes'];
    if (likes is List && likes.isNotEmpty) {
      final first = likes.first;
      if (first is Map) {
        final count = first['count'];
        if (count is int) return count;
        if (count is num) return count.toInt();
      }
    }
    return 0;
  }

  static int _parseViewCount(Map<String, dynamic> json) {
    final direct = json['view_count'];
    if (direct is int) return direct;
    if (direct is num) return direct.toInt();
    if (direct is String) return int.tryParse(direct) ?? 0;
    return 0;
  }
}
