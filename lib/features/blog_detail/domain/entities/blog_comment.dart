import 'package:Readme/features/home_page/domain/entities/blog.dart';

class BlogComment {
  const BlogComment({
    required this.id,
    required this.blogId,
    required this.body,
    required this.createdAt,
    required this.author,
    this.parentId,
    this.likeCount = 0,
    this.isLiked = false,
    this.replies = const [],
  });

  final String id;
  final String blogId;
  final String? parentId;
  final String body;
  final DateTime createdAt;
  final Author author;
  final int likeCount;
  final bool isLiked;
  final List<BlogComment> replies;

  bool get isTopLevel => parentId == null;

  int get replyCount => replies.length;

  BlogComment copyWith({
    String? id,
    String? blogId,
    String? parentId,
    String? body,
    DateTime? createdAt,
    Author? author,
    int? likeCount,
    bool? isLiked,
    List<BlogComment>? replies,
  }) {
    return BlogComment(
      id: id ?? this.id,
      blogId: blogId ?? this.blogId,
      parentId: parentId ?? this.parentId,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      author: author ?? this.author,
      likeCount: likeCount ?? this.likeCount,
      isLiked: isLiked ?? this.isLiked,
      replies: replies ?? this.replies,
    );
  }
}
