import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/blog_model.dart';
import '../../../search/data/models/explore_article_model.dart';

class BlogRemoteDatasource {
  final SupabaseClient client;

  BlogRemoteDatasource(this.client);

  static const String _blogSelectWithAuthors = '''
      blog_id,
      title,
      content,
      cover_image,
      created_at,
      category,
      is_published,
      community_id,
      profiles!inner (
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

  Future<List<BlogModel>> fetchBlogs() async {
    final response = await client
        .from('blogs')
        .select(_blogSelectWithAuthors)
        .eq('is_published', true)
        .order('created_at', ascending: false);

    return response.map<BlogModel>((e) => BlogModel.fromJson(e)).toList();
  }

  Future<List<BlogModel>> fetchBlogsByAuthor(String authorId) async {
    final response = await client
        .from('blogs')
        .select(_blogSelectWithAuthors)
        .eq('author_id', authorId)
        .eq('is_published', true)
        .order('created_at', ascending: false);

    return response.map<BlogModel>((e) => BlogModel.fromJson(e)).toList();
  }

  Future<List<String>> fetchCategories() async {
    final response = await client
        .from('blogs')
        .select('category')
        .eq('is_published', true);

    final categories = response
        .map((e) => e['category'] as String)
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList();

    return categories;
  }

  Future<List<ExploreArticle>> fetchExploreArticles() async {
    final response = await client
        .from('blogs')
        .select('''
      blog_id,
      title,
      content,
      cover_image,
      created_at,
      category,
      is_published,
      community_id,
      profiles!inner (
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
    ''')
        .eq('is_published', true)
        .order('created_at', ascending: false);

    return response
        .map<ExploreArticle>((row) => ExploreArticle.fromJson(row))
        .toList();
  }
}
