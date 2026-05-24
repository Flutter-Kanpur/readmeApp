import 'package:Readme/core/utils/app_colors.dart';
import 'package:Readme/core/utils/app_image.dart';
import 'package:Readme/core/utils/quill_content_parser.dart';
import 'package:Readme/core/utils/text_style.dart';
import 'package:Readme/features/home_page/domain/entities/blog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class ProfileBlogCard extends StatelessWidget {
  const ProfileBlogCard({
    super.key,
    required this.blog,
    this.onEdit,
  });

  final Blog blog;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16.r,
                backgroundColor: Colors.grey.shade200,
                backgroundImage:
                    imageProviderFromSource(blog.author.avatarUrl),
                child: blog.author.avatarUrl == null
                    ? Icon(Icons.person, size: 18.r, color: Colors.grey)
                    : null,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  blog.author.name,
                  style: textStyle_16BoldBlack().copyWith(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Material(
                color: AppColors.black,
                borderRadius: BorderRadius.circular(999),
                child: InkWell(
                  onTap: onEdit,
                  borderRadius: BorderRadius.circular(999),
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                    child: Text(
                      'Edit Blog',
                      style: textStyle_14RegularBlack().copyWith(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          GestureDetector(
            onTap: () => context.push('/blog/${blog.id}', extra: blog),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  blog.title,
                  style: textStyle_16BoldBlack().copyWith(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 10.h),
                Text(
                  parseQuillContent(blog.content),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: textStyle_14RegularGrey().copyWith(
                    fontSize: 14.sp,
                    color: AppColors.subtitles,
                    height: 1.45,
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
