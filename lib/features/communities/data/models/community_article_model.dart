import 'package:Readme/features/home_page/data/models/blog_model.dart';
import 'package:Readme/features/home_page/domain/entities/blog.dart';

class CommunityArticle {
  const CommunityArticle({
    required this.blog,
    required this.authors,
  });

  final Blog blog;
  final List<Author> authors;

  factory CommunityArticle.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'];
    final primaryAuthor = Author(
      name: profile?['name'] as String? ?? 'Unknown',
      avatarUrl: profile?['avatar_url'] as String?,
    );

    final coauthors = (json['blog_coauthors'] as List? ?? [])
        .map((entry) {
          final coProfile = entry['profiles'] as Map<String, dynamic>?;
          return Author(
            name: coProfile?['name'] as String? ?? 'Unknown',
            avatarUrl: coProfile?['avatar_url'] as String?,
          );
        })
        .where((author) => author.name != primaryAuthor.name)
        .toList();

    return CommunityArticle(
      blog: BlogModel.fromJson(json),
      authors: [primaryAuthor, ...coauthors],
    );
  }
}

class CommunityStats {
  const CommunityStats({
    required this.memberCount,
    required this.publishedCount,
  });

  final int memberCount;
  final int publishedCount;
}
