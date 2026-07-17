import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/blog_model.dart';
import '../../../search/data/models/explore_article_model.dart';

class BlogRemoteDatasource {
  BlogRemoteDatasource(this.client);

  final SupabaseClient client;

  static const defaultPageSize = 30;

  /// Includes `content` so list cards can show a subtitle preview.
  /// Pagination (`range`) keeps payload size bounded.
  static const String _blogListSelectBase = '''
      blog_id,
      author_id,
      title,
      content,
      cover_image,
      created_at,
      category,
      is_published,
      community_id,
      view_count,
      profiles!inner (
        id,
        name,
        avatar_url
      ),
      communities (
        name,
        logo_url
      ),
      blog_coauthors (
        user_id,
        profiles (
          name,
          avatar_url
        )
      )
    ''';

  static const String _blogDetailSelectBase = '''
      blog_id,
      author_id,
      title,
      content,
      cover_image,
      created_at,
      category,
      is_published,
      community_id,
      view_count,
      profiles!inner (
        id,
        name,
        avatar_url
      ),
      communities (
        name,
        logo_url
      ),
      blog_coauthors (
        user_id,
        profiles (
          name,
          avatar_url
        )
      )
    ''';

  static const String _blogListSelectWithLikes =
      '''
      $_blogListSelectBase,
      blog_likes (count)
    ''';

  static const String _blogDetailSelectWithLikes =
      '''
      $_blogDetailSelectBase,
      blog_likes (count)
    ''';

  bool _likesUnavailable = false;
  bool _viewCountUnavailable = false;

  String get _blogListSelect {
    var select = _likesUnavailable ? _blogListSelectBase : _blogListSelectWithLikes;
    if (_viewCountUnavailable) {
      select = select.replaceAll(RegExp(r',\s*view_count'), '');
    }
    return select;
  }

  String get _blogDetailSelect {
    var select =
        _likesUnavailable ? _blogDetailSelectBase : _blogDetailSelectWithLikes;
    if (_viewCountUnavailable) {
      select = select.replaceAll(RegExp(r',\s*view_count'), '');
    }
    return select;
  }

  bool _isMissingLikesRelation(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('blog_likes') ||
        message.contains('could not find') ||
        message.contains('relationship') ||
        message.contains('pgrst200');
  }

  bool _isMissingViewCount(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('view_count') ||
        message.contains('column') && message.contains('does not exist');
  }

  Future<List<Map<String, dynamic>>> _selectPublishedBlogs({
    String? authorId,
    int limit = defaultPageSize,
    int offset = 0,
  }) async {
    Future<List<Map<String, dynamic>>> run(String select) async {
      var query = client.from('blogs').select(select);
      if (authorId != null) {
        query = query.eq('author_id', authorId);
      }
      final response = await query
          .eq('is_published', true)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      return List<Map<String, dynamic>>.from(response as List);
    }

    try {
      return await run(_blogListSelect);
    } catch (e) {
      if (!_viewCountUnavailable && _isMissingViewCount(e)) {
        _viewCountUnavailable = true;
        return _selectPublishedBlogs(
          authorId: authorId,
          limit: limit,
          offset: offset,
        );
      }
      if (_likesUnavailable || !_isMissingLikesRelation(e)) rethrow;
      _likesUnavailable = true;
      return run(_blogListSelect);
    }
  }

  Future<BlogModel?> fetchBlogById(String blogId) async {
    Future<Map<String, dynamic>?> run(String select) async {
      final response = await client
          .from('blogs')
          .select(select)
          .eq('blog_id', blogId)
          .eq('is_published', true)
          .maybeSingle();
      if (response == null) return null;
      return Map<String, dynamic>.from(response);
    }

    try {
      final row = await run(_blogDetailSelect);
      return row == null ? null : BlogModel.fromJson(row);
    } catch (e) {
      if (!_viewCountUnavailable && _isMissingViewCount(e)) {
        _viewCountUnavailable = true;
        return fetchBlogById(blogId);
      }
      if (_likesUnavailable || !_isMissingLikesRelation(e)) rethrow;
      _likesUnavailable = true;
      final row = await run(_blogDetailSelect);
      return row == null ? null : BlogModel.fromJson(row);
    }
  }

  Future<List<BlogModel>> fetchBlogs({
    int limit = defaultPageSize,
    int offset = 0,
  }) async {
    final response = await _selectPublishedBlogs(limit: limit, offset: offset);
    return response.map<BlogModel>((e) => BlogModel.fromJson(e)).toList();
  }

  Future<List<BlogModel>> fetchBlogsByAuthor(
    String authorId, {
    int limit = defaultPageSize,
    int offset = 0,
  }) async {
    final response = await _selectPublishedBlogs(
      authorId: authorId,
      limit: limit,
      offset: offset,
    );
    return response.map<BlogModel>((e) => BlogModel.fromJson(e)).toList();
  }

  Future<List<String>> fetchCategories() async {
    final response = await client
        .from('blogs')
        .select('category')
        .eq('is_published', true)
        .limit(200);

    final categories = response
        .map((e) => e['category'] as String)
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList();

    return categories;
  }

  Future<List<ExploreArticle>> fetchExploreArticles({
    int limit = defaultPageSize,
    int offset = 0,
  }) async {
    final response = await _selectPublishedBlogs(limit: limit, offset: offset);
    return response
        .map<ExploreArticle>((row) => ExploreArticle.fromJson(row))
        .toList();
  }
}
