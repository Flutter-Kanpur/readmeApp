import 'package:Readme/features/blog_detail/domain/entities/blog_comment.dart';
import 'package:Readme/features/home_page/domain/entities/blog.dart';

class BlogCommentModel extends BlogComment {
  const BlogCommentModel({
    required super.id,
    required super.blogId,
    required super.body,
    required super.createdAt,
    required super.author,
    super.parentId,
    super.likeCount,
    super.isLiked,
    super.replies,
  });

  factory BlogCommentModel.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return BlogCommentModel(
      id: json['id'] as String,
      blogId: json['blog_id'] as String,
      parentId: json['parent_id'] as String?,
      body: json['body'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      likeCount: _parseInt(json['like_count']),
      author: Author(
        id: profile?['id'] as String? ?? json['user_id'] as String?,
        name: profile?['name'] as String? ?? 'Unknown',
        avatarUrl: profile?['avatar_url'] as String?,
      ),
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
