class Community {
  const Community({
    required this.id,
    required this.slug,
    required this.name,
    this.description,
    this.logoUrl,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String slug;
  final String name;
  final String? description;
  final String? logoUrl;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
}
