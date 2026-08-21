import 'package:Readme/core/providers/datasource_providers.dart';
import 'package:Readme/core/providers/supabase_providers.dart';
import 'package:Readme/core/utils/app_colors.dart';
import 'package:Readme/core/utils/relative_time.dart';
import 'package:Readme/core/utils/text_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class BlogCommentLikeButton extends ConsumerStatefulWidget {
  const BlogCommentLikeButton({
    super.key,
    required this.commentId,
    required this.initialLikeCount,
    required this.initialIsLiked,
    required this.onChanged,
  });

  final String commentId;
  final int initialLikeCount;
  final bool initialIsLiked;
  final void Function(bool isLiked, int likeCount) onChanged;

  @override
  ConsumerState<BlogCommentLikeButton> createState() =>
      _BlogCommentLikeButtonState();
}

class _BlogCommentLikeButtonState extends ConsumerState<BlogCommentLikeButton> {
  late bool _isLiked;
  late int _likeCount;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.initialIsLiked;
    _likeCount = widget.initialLikeCount;
  }

  @override
  void didUpdateWidget(covariant BlogCommentLikeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.commentId != widget.commentId) {
      _isLiked = widget.initialIsLiked;
      _likeCount = widget.initialLikeCount;
    } else {
      if (oldWidget.initialIsLiked != widget.initialIsLiked) {
        _isLiked = widget.initialIsLiked;
      }
      if (oldWidget.initialLikeCount != widget.initialLikeCount) {
        _likeCount = widget.initialLikeCount;
      }
    }
  }

  Future<void> _toggle() async {
    if (_loading) return;

    final user = ref.read(currentUserProvider);
    if (user == null) {
      if (mounted) context.push('/signin');
      return;
    }

    final wasLiked = _isLiked;
    final previousCount = _likeCount;
    setState(() {
      _loading = true;
      _isLiked = !wasLiked;
      _likeCount = wasLiked ? _likeCount - 1 : _likeCount + 1;
    });
    widget.onChanged(_isLiked, _likeCount);

    try {
      final datasource = ref.read(blogCommentDatasourceProvider);
      if (wasLiked) {
        await datasource.unlikeComment(
          commentId: widget.commentId,
          userId: user.id,
        );
      } else {
        await datasource.likeComment(
          commentId: widget.commentId,
          userId: user.id,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLiked = wasLiked;
        _likeCount = previousCount;
      });
      widget.onChanged(wasLiked, previousCount);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _loading ? null : _toggle,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isLiked ? Icons.favorite : Icons.favorite_border,
                size: 18.sp,
                color: _isLiked ? const Color(0xFFE11D48) : AppColors.subtitles,
              ),
              SizedBox(width: 6.w),
              Text(
                formatEngagementCount(_likeCount),
                style: textStyle_12RegularGrey().copyWith(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
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
}
