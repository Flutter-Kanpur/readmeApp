class ArticleCategoryFilter {
  const ArticleCategoryFilter({
    required this.label,
    this.category,
    this.communitiesOnly = false,
  });

  final String label;
  final String? category;
  final bool communitiesOnly;

  bool get isForYou => label == 'For You' && !communitiesOnly;

  static const forYou = ArticleCategoryFilter(label: 'For You');

  static const List<ArticleCategoryFilter> all = [
    forYou,
    ArticleCategoryFilter(label: 'Communities', communitiesOnly: true),
    ArticleCategoryFilter(label: 'Backend', category: 'Backend'),
    ArticleCategoryFilter(label: 'Design', category: 'Design'),
    ArticleCategoryFilter(label: 'Technology', category: 'Technology'),
    ArticleCategoryFilter(label: 'React', category: 'React'),
    ArticleCategoryFilter(label: 'DSA', category: 'DSA'),
    ArticleCategoryFilter(label: 'UI', category: 'UI'),
    ArticleCategoryFilter(label: 'Flutter', category: 'Flutter'),
  ];
}

bool matchesArticleCategoryFilter({
  required String blogCategory,
  required String? communityId,
  required ArticleCategoryFilter filter,
}) {
  if (filter.isForYou) return true;
  if (filter.communitiesOnly) {
    return communityId != null && communityId.isNotEmpty;
  }
  if (filter.category != null) {
    return blogCategory.toLowerCase() == filter.category!.toLowerCase();
  }
  return true;
}
