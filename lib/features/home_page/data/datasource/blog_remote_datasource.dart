import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/blog_model.dart';
import '../../../search/data/models/explore_article_model.dart';

class BlogRemoteDatasource {
  BlogRemoteDatasource(this.client);

  final SupabaseClient client;

  static const defaultPageSize = 20;

  /// Includes `content` so list cards can show a subtitle preview.
  /// Pagination (`range`) keeps payload size bounded.
  /// Engagement uses denormalized columns — never `blog_likes (count)`.
  static const String _blogListSelectBase = '''
      blog_id,
      author_id,
      title,
      content,
      cover_image,
      created_at,
      published_at,
      category,
      is_published,
      community_id,
      view_count,
      like_count,
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
      published_at,
      category,
      is_published,
      community_id,
      view_count,
      like_count,
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

  bool _likeCountUnavailable = false;
  bool _viewCountUnavailable = false;
  bool _publishedAtUnavailable = false;

  String get _blogListSelect => _applySelectFallbacks(_blogListSelectBase);

  String get _blogDetailSelect => _applySelectFallbacks(_blogDetailSelectBase);

  String _applySelectFallbacks(String select) {
    var result = select;
    if (_viewCountUnavailable) {
      result = result.replaceAll(RegExp(r',\s*view_count'), '');
    }
    if (_likeCountUnavailable) {
      result = result.replaceAll(RegExp(r',\s*like_count'), '');
    }
    if (_publishedAtUnavailable) {
      result = result.replaceAll(RegExp(r',\s*published_at'), '');
    }
    return result;
  }

  bool _isMissingColumn(Object error, String column) {
    final message = error.toString().toLowerCase();
    return message.contains(column) &&
        (message.contains('column') ||
            message.contains('does not exist') ||
            message.contains('could not find'));
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
      final orderColumn =
          _publishedAtUnavailable ? 'created_at' : 'published_at';
      final response = await query
          .eq('is_published', true)
          .order(orderColumn, ascending: false, nullsFirst: false)
          .range(offset, offset + limit - 1);
      return List<Map<String, dynamic>>.from(response as List);
    }

    try {
      return await run(_blogListSelect);
    } catch (e) {
      if (!_viewCountUnavailable && _isMissingColumn(e, 'view_count')) {
        _viewCountUnavailable = true;
        return _selectPublishedBlogs(
          authorId: authorId,
          limit: limit,
          offset: offset,
        );
      }
      if (!_likeCountUnavailable && _isMissingColumn(e, 'like_count')) {
        _likeCountUnavailable = true;
        return _selectPublishedBlogs(
          authorId: authorId,
          limit: limit,
          offset: offset,
        );
      }
      if (!_publishedAtUnavailable && _isMissingColumn(e, 'published_at')) {
        _publishedAtUnavailable = true;
        return _selectPublishedBlogs(
          authorId: authorId,
          limit: limit,
          offset: offset,
        );
      }
      rethrow;
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
      if (!_viewCountUnavailable && _isMissingColumn(e, 'view_count')) {
        _viewCountUnavailable = true;
        return fetchBlogById(blogId);
      }
      if (!_likeCountUnavailable && _isMissingColumn(e, 'like_count')) {
        _likeCountUnavailable = true;
        return fetchBlogById(blogId);
      }
      if (!_publishedAtUnavailable && _isMissingColumn(e, 'published_at')) {
        _publishedAtUnavailable = true;
        return fetchBlogById(blogId);
      }
      rethrow;
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
