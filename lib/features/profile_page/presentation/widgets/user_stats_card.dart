import 'package:Readme/core/utils/app_colors.dart';
import 'package:Readme/core/utils/text_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class UserStatsCard extends StatelessWidget {
  const UserStatsCard({
    super.key,
    required this.memberSince,
    required this.followers,
    required this.following,
    required this.totalArticles,
  });

  final DateTime? memberSince;
  final int followers;
  final int following;
  final int totalArticles;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'USER STATISTICS',
            style: textStyle_16BoldBlack().copyWith(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          SizedBox(height: 8.h),
          _StatRow(
            label: 'Member Since',
            value: memberSince != null
                ? DateFormat('dd/MM/yyyy').format(memberSince!)
                : '—',
          ),
          _StatRow(label: 'Followers', value: '$followers'),
          _StatRow(label: 'Following', value: '$following'),
          _StatRow(
            label: 'Total Articles',
            value: '$totalArticles',
            showDivider: false,
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: textStyle_14RegularGrey().copyWith(
                  fontSize: 14.sp,
                  color: AppColors.subtitles,
                ),
              ),
              Text(
                value,
                style: textStyle_14RegularBlack().copyWith(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(color: Colors.grey.shade100, height: 1, thickness: 1),
      ],
    );
  }
}
