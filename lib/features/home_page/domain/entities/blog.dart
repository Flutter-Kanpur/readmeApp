class Blog {
  final String id;
  final String title;
  final String content;
  final String? coverImage;
  final String category;
  final DateTime createdAt;
  final bool isPublished;
  final Author author;

  const Blog({
    required this.id,
    required this.title,
    required this.content,
    this.coverImage,
    required this.category,
    required this.createdAt,
    required this.isPublished,
    required this.author,
  });
}

class Author {
  final String name;
  final String? avatarUrl;

  const Author({
    required this.name,
    this.avatarUrl,
  });
}
