import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/utils/app_colors.dart';

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
        padding: EdgeInsets.all(14.sp),
        decoration: BoxDecoration(
          color: _highlightColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderGrey.withOpacity(0.6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author row
            Row(
              children: [
                _shimmerBox(
                  width: 40,
                  height: 40,
                  shape: BoxShape.circle,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _shimmerBox(width: 100, height: 14, borderRadius: 6),
                      SizedBox(height: 8.h),
                      _shimmerBox(width: 130, height: 12, borderRadius: 6),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),
            Divider(height: 1, color: AppColors.borderGrey),
            SizedBox(height: 14.h),
            // Content row: text + image
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _shimmerBox(
                        width: double.infinity,
                        height: 12,
                        borderRadius: 6,
                      ),
                      SizedBox(height: 10.h),
                      _shimmerBox(
                        width: double.infinity,
                        height: 12,
                        borderRadius: 6,
                      ),
                      SizedBox(height: 10.h),
                      _shimmerBox(
                        width: double.infinity,
                        height: 12,
                        borderRadius: 6,
                      ),
                      SizedBox(height: 10.h),
                      _shimmerBox(
                        width: 140.w,
                        height: 12,
                        borderRadius: 6,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12.w),
                _shimmerBox(
                  width: 130.w,
                  height: 100.h,
                  borderRadius: 15,
                ),
              ],
            ),
            SizedBox(height: 18.h),
            // Tag + Read more row
            Row(
              children: [
                _shimmerBox(
                  width: 72,
                  height: 30,
                  borderRadius: 20,
                ),
                const Spacer(),
                _shimmerBox(
                  width: 76,
                  height: 22,
                  borderRadius: 6,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
