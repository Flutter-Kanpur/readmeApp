import 'package:Readme/core/state/blog_engagement_provider.dart';
import 'package:Readme/core/utils/app_colors.dart';
import 'package:Readme/core/utils/text_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Displays how many times an article has been viewed / read.
///
/// When [blogId] is set, prefers the session [blogEngagementProvider] so list
/// and detail stay aligned after a view is recorded.
class BlogViewCount extends ConsumerWidget {
  const BlogViewCount({
    super.key,
    required this.count,
    this.blogId,
    this.compact = true,
  });

  final int count;
  final String? blogId;
  final bool compact;

  String _formatCount(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return '$value';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = blogId;
    if (id == null) {
      return _buildRow(count);
    }

    final resolved = ref.watch(
      blogEngagementProvider.select((m) => m[id]?.viewCount ?? count),
    );
    return _buildRow(resolved);
  }

  Widget _buildRow(int resolvedCount) {
    final label = _formatCount(resolvedCount);
    final iconSize = compact ? 18.sp : 20.sp;
    final fontSize = compact ? 12.sp : 14.sp;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.remove_red_eye_outlined,
          size: iconSize,
          color: AppColors.subtitles,
        ),
        SizedBox(width: 6.w),
        Text(
          compact ? label : '$label ${resolvedCount == 1 ? 'view' : 'views'}',
          style: textStyle_12RegularGrey().copyWith(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: AppColors.subtitles,
          ),
        ),
      ],
    );
  }
}
