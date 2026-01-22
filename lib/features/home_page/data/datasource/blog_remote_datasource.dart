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
          author_id
        ''')
        .eq('is_published', true)
        .order('created_at', ascending: false);

    return response
        .map<BlogModel>((e) => BlogModel.fromJson(e))
        .toList();
  }
}
