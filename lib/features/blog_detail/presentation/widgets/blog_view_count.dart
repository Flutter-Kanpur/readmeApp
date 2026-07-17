import 'package:Readme/core/utils/app_colors.dart';
import 'package:Readme/core/utils/text_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Displays how many times an article has been viewed / read.
class BlogViewCount extends StatelessWidget {
  const BlogViewCount({
    super.key,
    required this.count,
    this.compact = true,
  });

  final int count;
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
  Widget build(BuildContext context) {
    final label = _formatCount(count);
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
          compact ? label : '$label ${count == 1 ? 'view' : 'views'}',
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
