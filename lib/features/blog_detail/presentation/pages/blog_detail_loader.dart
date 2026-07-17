import 'package:Readme/features/blog_detail/presentation/pages/blog_detail_screen.dart';
import 'package:Readme/features/home_page/data/datasource/blog_remote_datasource.dart';
import 'package:Readme/features/home_page/domain/entities/blog.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Loads full blog content on demand so list screens can omit the heavy body.
class BlogDetailLoader extends StatefulWidget {
  const BlogDetailLoader({super.key, required this.blog});

  final Blog blog;

  @override
  State<BlogDetailLoader> createState() => _BlogDetailLoaderState();
}

class _BlogDetailLoaderState extends State<BlogDetailLoader> {
  late Blog _blog;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _blog = widget.blog;
    if (_blog.content.trim().isEmpty) {
      _loadFullBlog();
    }
  }

  Future<void> _loadFullBlog() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final datasource = BlogRemoteDatasource(Supabase.instance.client);
      final fullBlog = await datasource.fetchBlogById(_blog.id);
      if (!mounted) return;

      if (fullBlog == null) {
        setState(() {
          _error = 'This article could not be loaded.';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _blog = fullBlog;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load article: $error';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(_error!, textAlign: TextAlign.center),
          ),
        ),
      );
    }

    return BlogDetailScreen(blog: _blog);
  }
}
