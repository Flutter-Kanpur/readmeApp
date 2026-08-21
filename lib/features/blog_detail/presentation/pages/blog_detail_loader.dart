import 'package:Readme/core/providers/datasource_providers.dart';
import 'package:Readme/core/state/blog_engagement_provider.dart';
import 'package:Readme/features/blog_detail/presentation/pages/blog_detail_screen.dart';
import 'package:Readme/features/home_page/domain/entities/blog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Loads full blog content on demand and records a view when opened.
class BlogDetailLoader extends ConsumerStatefulWidget {
  const BlogDetailLoader({super.key, required this.blogId, this.initialBlog});

  final String blogId;
  final Blog? initialBlog;

  @override
  ConsumerState<BlogDetailLoader> createState() => _BlogDetailLoaderState();
}

class _BlogDetailLoaderState extends ConsumerState<BlogDetailLoader> {
  Blog? _blog;
  bool _isLoading = false;
  String? _error;
  bool _viewRecorded = false;

  bool get _hasCachedContent =>
      widget.initialBlog != null &&
      widget.initialBlog!.content.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (_hasCachedContent) {
      _blog = widget.initialBlog;
      ref.read(blogEngagementProvider.notifier).seedEngagementFromBlog(_blog!);
      _recordView();
    } else {
      _loadFullBlog();
    }
  }

  Future<void> _loadFullBlog() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final datasource = ref.read(blogRemoteDatasourceProvider);
      final fullBlog = await datasource.fetchBlogById(widget.blogId);
      if (!mounted) return;

      if (fullBlog == null) {
        setState(() {
          _error = 'This article could not be loaded.';
          _isLoading = false;
        });
        return;
      }

      ref.read(blogEngagementProvider.notifier).seedEngagementFromBlog(fullBlog);
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
    if (_viewRecorded || _blog == null) return;
    _viewRecorded = true;

    final latest = await ref
        .read(blogViewDatasourceProvider)
        .recordView(_blog!.id);

    if (!mounted || latest == null) return;

    ref.read(blogEngagementProvider.notifier).applyViewCount(_blog!.id, latest);
    if (latest != _blog!.viewCount) {
      setState(() => _blog = _blog!.copyWith(viewCount: latest));
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

    final blog = _blog;
    if (blog == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return BlogDetailScreen(blog: blog);
  }
}
