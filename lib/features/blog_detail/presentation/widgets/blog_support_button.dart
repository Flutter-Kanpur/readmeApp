import 'package:Readme/core/cache/blog_engagement_store.dart';
import 'package:Readme/core/cache/blog_like_cache.dart';
import 'package:Readme/core/network/readme_supabase.dart';
import 'package:Readme/core/utils/app_colors.dart';
import 'package:Readme/core/utils/text_style.dart';
import 'package:Readme/features/blog_detail/data/datasource/blog_like_datasource.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// Heart-style support control for articles.
///
/// Counts come from [BlogEngagementStore] (seeded from feed rows). Liked state
/// comes from [BlogLikeCache] (batch-preloaded). Never re-counts likes on mount.
class BlogSupportButton extends StatefulWidget {
  const BlogSupportButton({
    super.key,
    required this.blogId,
    this.initialLikeCount = 0,
    this.initialIsLiked,
    this.compact = false,
  });

  final String blogId;
  final int initialLikeCount;
  final bool? initialIsLiked;
  final bool compact;

  @override
  State<BlogSupportButton> createState() => _BlogSupportButtonState();
}

class _BlogSupportButtonState extends State<BlogSupportButton>
    with SingleTickerProviderStateMixin {
  late final BlogLikeDatasource _datasource;
  late AnimationController _bounceController;
  late Animation<double> _bounceScale;

  bool _isLiked = false;
  bool _actionLoading = false;

  @override
  void initState() {
    super.initState();
    _datasource = BlogLikeDatasource(ReadmeSupabase.client);
    final store = BlogEngagementStore.instance;
    store.seed(
      blogId: widget.blogId,
      likeCount: widget.initialLikeCount,
      viewCount: store.viewCount(widget.blogId),
    );
    _isLiked = _resolveLiked();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _bounceScale =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.28), weight: 40),
          TweenSequenceItem(tween: Tween(begin: 1.28, end: 0.92), weight: 30),
          TweenSequenceItem(tween: Tween(begin: 0.92, end: 1.0), weight: 30),
        ]).animate(
          CurvedAnimation(parent: _bounceController, curve: Curves.easeOut),
        );
    BlogEngagementStore.instance.addListener(_onStoreChanged);
  }

  @override
  void didUpdateWidget(covariant BlogSupportButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    final store = BlogEngagementStore.instance;
    if (oldWidget.blogId != widget.blogId) {
      store.seed(
        blogId: widget.blogId,
        likeCount: widget.initialLikeCount,
        viewCount: store.viewCount(widget.blogId),
      );
      _isLiked = _resolveLiked();
    } else if (oldWidget.initialLikeCount != widget.initialLikeCount) {
      store.seed(
        blogId: widget.blogId,
        likeCount: widget.initialLikeCount,
        viewCount: store.viewCount(widget.blogId),
      );
    }
  }

  @override
  void dispose() {
    BlogEngagementStore.instance.removeListener(_onStoreChanged);
    _bounceController.dispose();
    super.dispose();
  }

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  bool _resolveLiked() {
    if (widget.initialIsLiked != null) return widget.initialIsLiked!;
    return BlogLikeCache.instance.isLiked(widget.blogId) ?? false;
  }

  int get _likeCount => BlogEngagementStore.instance.likeCount(
        widget.blogId,
        fallback: widget.initialLikeCount,
      );

  Future<void> _toggleSupport() async {
    if (_actionLoading) return;

    final user = ReadmeSupabase.client.auth.currentUser;
    if (user == null) {
      context.push('/signin');
      return;
    }

    final wasLiked = _isLiked;
    final previousCount = _likeCount;

    setState(() {
      _isLiked = !wasLiked;
      _actionLoading = true;
    });
    BlogLikeCache.instance.setLiked(widget.blogId, !wasLiked);
    BlogEngagementStore.instance.applyLikeDelta(
      widget.blogId,
      liked: !wasLiked,
    );

    if (!wasLiked) {
      _bounceController.forward(from: 0);
    }

    try {
      if (wasLiked) {
        await _datasource.unlikeBlog(blogId: widget.blogId, userId: user.id);
      } else {
        await _datasource.likeBlog(blogId: widget.blogId, userId: user.id);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLiked = wasLiked);
      BlogLikeCache.instance.setLiked(widget.blogId, wasLiked);
      BlogEngagementStore.instance.setLikeCount(widget.blogId, previousCount);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return '$count';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      return _buildCompact();
    }
    return _buildExpanded();
  }

  Widget _buildHeart({required double size}) {
    return ScaleTransition(
      scale: _bounceScale,
      child: Icon(
        _isLiked ? Icons.favorite : Icons.favorite_border,
        size: size,
        color: _isLiked ? const Color(0xFFE11D48) : AppColors.subtitles,
      ),
    );
  }

  Widget _buildCompact() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _actionLoading ? null : _toggleSupport,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeart(size: 18.sp),
              SizedBox(width: 6.w),
              Text(
                _formatCount(_likeCount),
                style: textStyle_12RegularGrey().copyWith(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: _isLiked
                      ? const Color(0xFFE11D48)
                      : AppColors.subtitles,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpanded() {
    final label = _isLiked ? 'Supported' : 'Support';
    final countLabel = ' · ${_formatCount(_likeCount)}';

    return Material(
      color: _isLiked ? const Color(0xFFFFF1F2) : Colors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: _actionLoading ? null : _toggleSupport,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: _isLiked
                  ? const Color(0xFFE11D48).withOpacity(0.35)
                  : AppColors.borderGrey,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeart(size: 20.sp),
              SizedBox(width: 10.w),
              Text(
                '$label$countLabel',
                style: textStyle_14RegularBlack().copyWith(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: _isLiked ? const Color(0xFFE11D48) : AppColors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
