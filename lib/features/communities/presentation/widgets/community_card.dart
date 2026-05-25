import 'package:Readme/core/utils/app_colors.dart';
import 'package:Readme/core/utils/app_image.dart';
import 'package:Readme/core/utils/text_style.dart';
import 'package:Readme/features/communities/domain/entities/community.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CommunityCard extends StatelessWidget {
  const CommunityCard({
    super.key,
    required this.community,
    this.onTap,
  });

  final Community community;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.grey.shade200),
          ),
          padding: EdgeInsets.all(16.w),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10.r),
                child: SizedBox(
                  width: 72.w,
                  height: 72.w,
                  child: AppImage(
                    source: community.logoUrl,
                    fit: BoxFit.cover,
                    width: 72.w,
                    height: 72.w,
                    placeholder: Container(
                      color: Colors.grey.shade100,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.groups_outlined,
                        size: 32.sp,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      community.name,
                      style: textStyle_16BoldBlack().copyWith(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (community.description != null &&
                        community.description!.trim().isNotEmpty) ...[
                      SizedBox(height: 6.h),
                      Text(
                        community.description!,
                        style: textStyle_14RegularGrey().copyWith(
                          fontSize: 14.sp,
                          height: 1.45,
                          color: AppColors.subtitles,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
