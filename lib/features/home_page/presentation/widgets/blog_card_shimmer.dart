import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

class BlogCardShimmer extends StatelessWidget {
  const BlogCardShimmer({super.key});

  static const _baseColor = Color(0xFFE6E6E6);
  static const _highlightColor = Color(0xFFF7F7F7);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CommunityTagShimmer(),
          SizedBox(height: 16.h),
          _AuthorRowShimmer(),
          SizedBox(height: 18.h),
          _ShimmerLine(width: double.infinity, height: 20.h, radius: 6),
          SizedBox(height: 8.h),
          _ShimmerLine(width: 220.w, height: 20.h, radius: 6),
          SizedBox(height: 16.h),
          _ShimmerLine(width: double.infinity, height: 14.h, radius: 6),
          SizedBox(height: 8.h),
          _ShimmerLine(width: double.infinity, height: 14.h, radius: 6),
          SizedBox(height: 8.h),
          _ShimmerLine(width: 180.w, height: 14.h, radius: 6),
        ],
      ),
    );
  }
}

class _ShimmerLine extends StatelessWidget {
  const _ShimmerLine({
    required this.width,
    required this.height,
    this.radius = 6,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: BlogCardShimmer._baseColor,
      highlightColor: BlogCardShimmer._highlightColor,
      period: const Duration(milliseconds: 1200),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: BlogCardShimmer._baseColor,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

class _CommunityTagShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: BlogCardShimmer._baseColor,
      highlightColor: BlogCardShimmer._highlightColor,
      period: const Duration(milliseconds: 1200),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: BlogCardShimmer._baseColor,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 14.w,
                  height: 14.w,
                  decoration: BoxDecoration(
                    color: BlogCardShimmer._highlightColor,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
                SizedBox(width: 8.w),
                Container(
                  width: 80.w,
                  height: 10.h,
                  decoration: BoxDecoration(
                    color: BlogCardShimmer._highlightColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          Container(
            width: 70.w,
            height: 10.h,
            decoration: BoxDecoration(
              color: BlogCardShimmer._baseColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthorRowShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: BlogCardShimmer._baseColor,
      highlightColor: BlogCardShimmer._highlightColor,
      period: const Duration(milliseconds: 1200),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 36.w,
            height: 36.w,
            decoration: const BoxDecoration(
              color: BlogCardShimmer._baseColor,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 180.w,
                  height: 14.h,
                  decoration: BoxDecoration(
                    color: BlogCardShimmer._baseColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                SizedBox(height: 6.h),
                Container(
                  width: 70.w,
                  height: 11.h,
                  decoration: BoxDecoration(
                    color: BlogCardShimmer._baseColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
