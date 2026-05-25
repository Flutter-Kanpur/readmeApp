import 'package:Readme/features/home_page/data/models/blog_model.dart';
import 'package:Readme/features/home_page/domain/entities/blog.dart';

class ExploreArticle {
  const ExploreArticle({
    required this.blog,
    required this.authors,
    this.communityName,
    this.communityLogoUrl,
  });

  final Blog blog;
  final List<Author> authors;
  final String? communityName;
  final String? communityLogoUrl;

  factory ExploreArticle.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    final community = json['communities'] as Map<String, dynamic>?;
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

    return ExploreArticle(
      blog: BlogModel.fromJson(json),
      authors: [primaryAuthor, ...coauthors],
      communityName: community?['name'] as String?,
      communityLogoUrl: community?['logo_url'] as String?,
    );
  }
}
