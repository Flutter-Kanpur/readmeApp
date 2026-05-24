import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/blog_model.dart';

class BlogRemoteDatasource {
  final SupabaseClient client;

  BlogRemoteDatasource(this.client);

  Future<List<BlogModel>> fetchBlogs() async {
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
      profiles!inner (
        name,
        avatar_url
      )
    ''')
        .eq('is_published', true)
        .order('created_at', ascending: false);

    return response.map<BlogModel>((e) => BlogModel.fromJson(e)).toList();
  }

  Future<List<BlogModel>> fetchBlogsByAuthor(String authorId) async {
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
      profiles!inner (
        name,
        avatar_url
      )
    ''')
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
}
