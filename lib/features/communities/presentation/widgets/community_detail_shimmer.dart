import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

class CommunityDetailShimmer extends StatelessWidget {
  const CommunityDetailShimmer({super.key});

  static const _baseColor = Color(0xFFE6E6E6);
  static const _highlightColor = Color(0xFFF7F7F7);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 32.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ShimmerLine(width: 160.w, height: 14.h),
          SizedBox(height: 24.h),
          _HeaderShimmer(),
          SizedBox(height: 24.h),
          _ShimmerPillButton(width: double.infinity, dark: true),
          SizedBox(height: 12.h),
          _ShimmerPillButton(width: double.infinity, dark: false),
          SizedBox(height: 28.h),
          Divider(color: Colors.grey.shade200, height: 1),
          SizedBox(height: 24.h),
          _ShimmerLine(width: 180.w, height: 22.h, radius: 6),
          SizedBox(height: 16.h),
          _ArticleCardShimmer(),
          SizedBox(height: 12.h),
          _ArticleCardShimmer(),
          SizedBox(height: 12.h),
          _ArticleCardShimmer(),
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
      baseColor: CommunityDetailShimmer._baseColor,
      highlightColor: CommunityDetailShimmer._highlightColor,
      period: const Duration(milliseconds: 1200),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: CommunityDetailShimmer._baseColor,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

class _ShimmerBlock extends StatelessWidget {
  const _ShimmerBlock({
    required this.width,
    required this.height,
    this.radius = 12,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: CommunityDetailShimmer._baseColor,
      highlightColor: CommunityDetailShimmer._highlightColor,
      period: const Duration(milliseconds: 1200),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: CommunityDetailShimmer._baseColor,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

class _HeaderShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ShimmerBlock(width: 88.w, height: 88.w, radius: 16),
        SizedBox(width: 16.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ShimmerLine(width: 180.w, height: 22.h),
              SizedBox(height: 10.h),
              _ShimmerLine(width: double.infinity, height: 12.h),
              SizedBox(height: 6.h),
              _ShimmerLine(width: 220.w, height: 12.h),
              SizedBox(height: 12.h),
              _ShimmerLine(width: 140.w, height: 12.h),
            ],
          ),
        ),
      ],
    );
  }
}

class _ShimmerPillButton extends StatelessWidget {
  const _ShimmerPillButton({
    required this.width,
    required this.dark,
  });

  final double width;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final baseColor = dark
        ? const Color(0xFFD4D4D4)
        : CommunityDetailShimmer._baseColor;
    final highlightColor =
        dark ? const Color(0xFFEFEFEF) : CommunityDetailShimmer._highlightColor;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      period: const Duration(milliseconds: 1200),
      child: Container(
        width: width,
        height: 48.h,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _ArticleCardShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ShimmerBlock(width: 110.w, height: 24.h, radius: 999),
              SizedBox(width: 10.w),
              _ShimmerLine(width: 80.w, height: 12.h),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              _ShimmerBlock(width: 36.w, height: 36.w, radius: 999),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ShimmerLine(width: 200.w, height: 14.h),
                    SizedBox(height: 6.h),
                    _ShimmerLine(width: 70.w, height: 11.h),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 18.h),
          _ShimmerLine(width: double.infinity, height: 18.h),
          SizedBox(height: 8.h),
          _ShimmerLine(width: 220.w, height: 18.h),
          SizedBox(height: 14.h),
          _ShimmerLine(width: double.infinity, height: 12.h),
          SizedBox(height: 6.h),
          _ShimmerLine(width: double.infinity, height: 12.h),
          SizedBox(height: 6.h),
          _ShimmerLine(width: 180.w, height: 12.h),
        ],
      ),
    );
  }
}
