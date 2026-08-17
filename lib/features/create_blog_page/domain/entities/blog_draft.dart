class BlogDraft {
  const BlogDraft({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.updatedAt,
    this.isLocalOnly = false,
  });

  /// Sentinel id for a device-local draft not yet synced to Supabase.
  static const localDraftId = '__local_draft__';

  final String id;
  final String title;
  final String content;
  final String category;
  final DateTime updatedAt;
  final bool isLocalOnly;
}
