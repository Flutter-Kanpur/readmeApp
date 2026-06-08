class Blog {
  final String id;
  final String title;
  final String content;
  final String? coverImage;
  final String category;
  final DateTime createdAt;
  final bool isPublished;
  final Author author;
  final List<Author> coauthors;
  final List<String>? imageUrls;
  final String? communityId;
  final String? communityName;
  final String? communityLogoUrl;

  const Blog({
    required this.id,
    required this.title,
    required this.content,
    this.coverImage,
    required this.category,
    required this.createdAt,
    required this.isPublished,
    required this.author,
    this.coauthors = const [],
    this.imageUrls,
    this.communityId,
    this.communityName,
    this.communityLogoUrl,
  });

  /// Primary author followed by all unique co-authors. Useful for cards that
  /// render a stacked avatar group / combined name list.
  List<Author> get allAuthors {
    final seen = <String>{};
    final unique = <Author>[];
    for (final author in [author, ...coauthors]) {
      final key = author.id ?? author.name;
      if (seen.add(key)) unique.add(author);
    }
    return unique;
  }
}

class Author {
  final String? id;
  final String name;
  final String? avatarUrl;

  const Author({
    this.id,
    required this.name,
    this.avatarUrl,
  });
}
