import 'package:Readme/core/utils/quill_content_parser.dart';
import 'package:Readme/core/utils/text_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_image.dart';
import '../../domain/entities/blog.dart';

class BlogCard extends StatelessWidget {
  final Blog blog;

  const BlogCard({super.key, required this.blog});

  String _previewText(String content) => parseQuillContent(content);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/blog/${blog.id}', extra: blog),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
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
            Text(
              blog.category.toUpperCase(),
              style: textStyle_14BoldLinkBlue().copyWith(
                fontSize: 10.sp,
                // letterSpacing: 0.6,
                color: AppColors.linkBlue,
              ),
            ),
            SizedBox(height: 14.h),
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
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            Text(
              blog.title,
              style: textStyle_16BoldBlack().copyWith(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 10.h),
            Text(
              _previewText(blog.content),
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
    );
  }
}
