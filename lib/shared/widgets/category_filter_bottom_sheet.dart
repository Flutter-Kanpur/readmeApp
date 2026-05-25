import 'package:Readme/core/utils/app_colors.dart';
import 'package:Readme/core/utils/text_style.dart';
import 'package:Readme/features/home_page/presentation/state/article_category_filters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

Future<ArticleCategoryFilter?> showCategoryFilterBottomSheet(
  BuildContext context, {
  required ArticleCategoryFilter selected,
}) {
  return showModalBottomSheet<ArticleCategoryFilter>(
    context: context,
    backgroundColor: Colors.white,
    isScrollControlled: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
    ),
    builder: (context) {
      return CategoryFilterBottomSheet(selected: selected);
    },
  );
}

class CategoryFilterBottomSheet extends StatelessWidget {
  const CategoryFilterBottomSheet({
    super.key,
    required this.selected,
  });

  final ArticleCategoryFilter selected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 24.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            SizedBox(height: 20.h),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Choose a Category',
                    style: textStyle_16BoldBlack().copyWith(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Material(
                  color: Colors.grey.shade100,
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    customBorder: const CircleBorder(),
                    child: Padding(
                      padding: EdgeInsets.all(8.w),
                      child: Icon(
                        Icons.close,
                        size: 20.sp,
                        color: AppColors.subtitles,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24.h),
            Wrap(
              spacing: 10.w,
              runSpacing: 10.h,
              children: ArticleCategoryFilter.all.map((filter) {
                final isSelected = filter.label == selected.label;
                return _CategoryPill(
                  label: filter.label,
                  isSelected: isSelected,
                  onTap: () => Navigator.pop(context, filter),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
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
          ),
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 11.h),
          child: Text(
            label,
            style: textStyle_14RegularBlack().copyWith(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : AppColors.black,
            ),
          ),
        ),
      ),
    );
  }
}
