import 'package:Readme/core/providers/datasource_providers.dart';
import 'package:Readme/core/providers/supabase_providers.dart';
import 'package:Readme/core/state/blog_engagement_provider.dart';
import 'package:Readme/core/state/blog_like_provider.dart';
import 'package:Readme/core/utils/app_colors.dart';
import 'package:Readme/core/utils/text_style.dart';
import 'package:Readme/features/blog_detail/data/datasource/blog_like_datasource.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// Heart-style support control for articles.
///
/// Counts come from [blogEngagementProvider] (seeded from feed rows); liked
/// state comes from [blogLikeProvider] (batch-preloaded). Both are watched, so
/// a like on any screen updates every mounted button. Never re-counts likes on
/// mount.
class BlogSupportButton extends ConsumerStatefulWidget {
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
  ConsumerState<BlogSupportButton> createState() => _BlogSupportButtonState();
}

class _BlogSupportButtonState extends ConsumerState<BlogSupportButton>
    with SingleTickerProviderStateMixin {
  late final BlogLikeDatasource _datasource;
  late final AnimationController _bounceController;
  late final Animation<double> _bounceScale;

  bool _actionLoading = false;

  @override
  void initState() {
    super.initState();
    _datasource = ref.read(blogLikeDatasourceProvider);
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
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  bool _resolveLiked(bool? liked) => liked ?? widget.initialIsLiked ?? false;

  Future<void> _toggleSupport(bool wasLiked, int previousCount) async {
    if (_actionLoading) return;

    final user = ref.read(currentUserProvider);
    if (user == null) {
      context.push('/signin');
      return;
    }

    final engagement = ref.read(blogEngagementProvider.notifier);
    // Ensure a base count exists before mutating so the delta increments from
    // the real value rather than from zero.
    engagement.seed(
      blogId: widget.blogId,
      likeCount: widget.initialLikeCount,
      viewCount: engagement.viewCount(widget.blogId),
    );

    setState(() => _actionLoading = true);
    ref.read(blogLikeProvider.notifier).setLiked(widget.blogId, !wasLiked);
    engagement.applyLikeDelta(widget.blogId, liked: !wasLiked);

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
      ref.read(blogLikeProvider.notifier).setLiked(widget.blogId, wasLiked);
      engagement.setLikeCount(widget.blogId, previousCount);
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
    final isLiked = _resolveLiked(
      ref.watch(blogLikeProvider.select((m) => m[widget.blogId])),
    );
    final likeCount = ref.watch(
      blogEngagementProvider.select(
        (m) => m[widget.blogId]?.likeCount ?? widget.initialLikeCount,
      ),
    );

    return widget.compact
        ? _buildCompact(isLiked: isLiked, likeCount: likeCount)
        : _buildExpanded(isLiked: isLiked, likeCount: likeCount);
  }

  Widget _buildHeart({required double size, required bool isLiked}) {
    return ScaleTransition(
      scale: _bounceScale,
      child: Icon(
        isLiked ? Icons.favorite : Icons.favorite_border,
        size: size,
        color: isLiked ? const Color(0xFFE11D48) : AppColors.subtitles,
      ),
    );
  }

  Widget _buildCompact({required bool isLiked, required int likeCount}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _actionLoading
            ? null
            : () => _toggleSupport(isLiked, likeCount),
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeart(size: 18.sp, isLiked: isLiked),
              SizedBox(width: 6.w),
              Text(
                _formatCount(likeCount),
                style: textStyle_12RegularGrey().copyWith(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: isLiked
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

  Widget _buildExpanded({required bool isLiked, required int likeCount}) {
    final label = isLiked ? 'Supported' : 'Support';
    final countLabel = ' · ${_formatCount(likeCount)}';

    return Material(
      color: isLiked ? const Color(0xFFFFF1F2) : Colors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: _actionLoading
            ? null
            : () => _toggleSupport(isLiked, likeCount),
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isLiked
                  ? const Color(0xFFE11D48).withOpacity(0.35)
                  : AppColors.borderGrey,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeart(size: 20.sp, isLiked: isLiked),
              SizedBox(width: 10.w),
              Text(
                '$label$countLabel',
                style: textStyle_14RegularBlack().copyWith(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: isLiked ? const Color(0xFFE11D48) : AppColors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
