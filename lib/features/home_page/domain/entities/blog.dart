class Blog {
  final String id;
  final String title;
  final String content;
  final String? coverImage;
  final String category;
  final DateTime createdAt;
  /// When the post went live. Prefer this over [createdAt] for feed ordering.
  final DateTime? publishedAt;
  final bool isPublished;
  final Author author;
  final List<Author> coauthors;
  final List<String>? imageUrls;
  final String? communityId;
  final String? communityName;
  final String? communityLogoUrl;
  final int likeCount;
  final int viewCount;

  const Blog({
    required this.id,
    required this.title,
    required this.content,
    this.coverImage,
    required this.category,
    required this.createdAt,
    this.publishedAt,
    required this.isPublished,
    required this.author,
    this.coauthors = const [],
    this.imageUrls,
    this.communityId,
    this.communityName,
    this.communityLogoUrl,
    this.likeCount = 0,
    this.viewCount = 0,
  });

  /// Sort / display time for published posts.
  DateTime get wentLiveAt => publishedAt ?? createdAt;

  Blog copyWith({
    String? id,
    String? title,
    String? content,
    String? coverImage,
    String? category,
    DateTime? createdAt,
    DateTime? publishedAt,
    bool? isPublished,
    Author? author,
    List<Author>? coauthors,
    List<String>? imageUrls,
    String? communityId,
    String? communityName,
    String? communityLogoUrl,
    int? likeCount,
    int? viewCount,
  }) {
    return Blog(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      coverImage: coverImage ?? this.coverImage,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      publishedAt: publishedAt ?? this.publishedAt,
      isPublished: isPublished ?? this.isPublished,
      author: author ?? this.author,
      coauthors: coauthors ?? this.coauthors,
      imageUrls: imageUrls ?? this.imageUrls,
      communityId: communityId ?? this.communityId,
      communityName: communityName ?? this.communityName,
      communityLogoUrl: communityLogoUrl ?? this.communityLogoUrl,
      likeCount: likeCount ?? this.likeCount,
      viewCount: viewCount ?? this.viewCount,
    );
  }

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

  const Author({this.id, required this.name, this.avatarUrl});
}
