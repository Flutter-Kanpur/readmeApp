import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

class BlogCardShimmer extends StatelessWidget {
  const BlogCardShimmer({super.key});

  static const _baseColor = Color(0xFFE0E0E0);
  static const _highlightColor = Color(0xFFF5F5F5);

  Widget _shimmerBox({
    required double width,
    required double height,
    double borderRadius = 8,
    BoxShape shape = BoxShape.rectangle,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: _baseColor,
        borderRadius: shape == BoxShape.rectangle
            ? BorderRadius.circular(borderRadius)
            : null,
        shape: shape,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: _baseColor,
      highlightColor: _highlightColor,
      period: const Duration(milliseconds: 1200),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
        decoration: BoxDecoration(
          color: _highlightColor,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _shimmerBox(width: 90, height: 13, borderRadius: 6),
            SizedBox(height: 14.h),
            Row(
              children: [
                _shimmerBox(width: 32, height: 32, shape: BoxShape.circle),
                SizedBox(width: 10.w),
                _shimmerBox(width: 140, height: 15, borderRadius: 6),
              ],
            ),
            SizedBox(height: 16.h),
            _shimmerBox(width: double.infinity, height: 20, borderRadius: 6),
            SizedBox(height: 8.h),
            _shimmerBox(width: double.infinity, height: 20, borderRadius: 6),
            SizedBox(height: 10.h),
            _shimmerBox(width: double.infinity, height: 14, borderRadius: 6),
            SizedBox(height: 8.h),
            _shimmerBox(width: double.infinity, height: 14, borderRadius: 6),
            SizedBox(height: 8.h),
            _shimmerBox(width: 180.w, height: 14, borderRadius: 6),
          ],
        ),
      ),
    );
  }
}
