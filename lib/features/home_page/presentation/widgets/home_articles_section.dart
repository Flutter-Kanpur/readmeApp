import 'package:Readme/core/utils/app_colors.dart';
import 'package:Readme/core/utils/text_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HomeArticlesSection extends StatelessWidget {
  const HomeArticlesSection({
    super.key,
    this.onSearchTap,
    this.onForYouTap,
    this.onFiltersTap,
    this.isForYouSelected = true,
    this.hasActiveFilter = false,
  });

  final VoidCallback? onSearchTap;
  final VoidCallback? onForYouTap;
  final VoidCallback? onFiltersTap;
  final bool isForYouSelected;
  final bool hasActiveFilter;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 48.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SearchBar(onTap: onSearchTap),
          SizedBox(height: 28.h),
          Text(
            'Latest Articles',
            style: textStyle_24BoldBlack().copyWith(
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
            ),
          ),
          SizedBox(height: 18.h),
          Row(
            children: [
              _FilterChip(
                label: 'For You',
                isSelected: isForYouSelected,
                onTap: onForYouTap,
              ),
              const Spacer(),
              _FilterChip(
                label: 'Filters',
                icon: Icons.tune_rounded,
                isSelected: hasActiveFilter,
                onTap: onFiltersTap,
              ),
            ],
          ),
          SizedBox(height: 18.h),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      elevation: 0,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
            child: Row(
              children: [
                Icon(Icons.search, size: 22.sp, color: AppColors.subtitles),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    'Search articles, topics, writers...',
                    style: textStyle_14RegularGrey().copyWith(
                      fontSize: 12.sp,
                      color: AppColors.subtitles,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F3F3),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Search',
                    style: textStyle_14RegularBlack().copyWith(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.subtitles,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    this.icon,
    required this.isSelected,
    this.onTap,
  });

  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      elevation: 0,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          decoration: BoxDecoration(
            color: isSelected ? AppColors.black : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: isSelected
                ? null
                : Border.all(color: Colors.grey.shade200),
            boxShadow: isSelected
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 18.sp,
                    color: isSelected ? Colors.white : AppColors.subtitles,
                  ),
                  SizedBox(width: 6.w),
                ],
                Text(
                  label,
                  style: textStyle_14RegularBlack().copyWith(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : AppColors.subtitles,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
