import 'package:Readme/core/cache/blog_engagement_store.dart';
import 'package:Readme/core/network/readme_supabase.dart';
import 'package:Readme/features/blog_detail/data/datasource/blog_view_datasource.dart';
import 'package:Readme/features/blog_detail/presentation/pages/blog_detail_screen.dart';
import 'package:Readme/features/home_page/data/datasource/blog_remote_datasource.dart';
import 'package:Readme/features/home_page/domain/entities/blog.dart';
import 'package:flutter/material.dart';

/// Loads full blog content on demand and records a view when opened.
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
  bool _viewRecorded = false;

  @override
  void initState() {
    super.initState();
    _blog = widget.blog;
    BlogEngagementStore.instance.seedEngagementFromBlog(_blog);
    if (_blog.content.trim().isEmpty) {
      _loadFullBlog();
    } else {
      _recordView();
    }
  }

  Future<void> _loadFullBlog() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final datasource = BlogRemoteDatasource(ReadmeSupabase.client);
      final fullBlog = await datasource.fetchBlogById(_blog.id);
      if (!mounted) return;

      if (fullBlog == null) {
        setState(() {
          _error = 'This article could not be loaded.';
          _isLoading = false;
        });
        return;
      }

      BlogEngagementStore.instance.seedEngagementFromBlog(fullBlog);
      setState(() {
        _blog = fullBlog;
        _isLoading = false;
      });
      await _recordView();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load article: $error';
        _isLoading = false;
      });
    }
  }

  Future<void> _recordView() async {
    if (_viewRecorded) return;
    _viewRecorded = true;

    final latest = await BlogViewDatasource(
      ReadmeSupabase.client,
    ).recordView(_blog.id);

    if (!mounted || latest == null) return;

    BlogEngagementStore.instance.applyViewCount(_blog.id, latest);
    if (latest != _blog.viewCount) {
      setState(() => _blog = _blog.copyWith(viewCount: latest));
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
