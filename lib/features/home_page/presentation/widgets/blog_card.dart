import 'package:Readme/core/utils/string_extensions.dart';
import 'package:Readme/core/utils/text_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/app_colors.dart';
import '../../domain/entities/blog.dart';
import 'dart:convert';

class BlogCard extends StatelessWidget {
  final Blog blog;

  const BlogCard({super.key, required this.blog});

  int _readTime(String text) {
    final words = text.split(' ').length;
    return (words / 200).ceil();
  }

  String _previewText(String content) {
    try {
      final List ops = jsonDecode(content);
      return ops
          .where((e) => e['insert'] is String)
          .map((e) => e['insert'] as String)
          .join()
          .replaceAll('\n', ' ')
          .trim();
    } catch (_) {
      return content;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.push('/blog/${blog.id}', extra: blog);
      },
      child: Container(
        padding: EdgeInsets.all(14.sp),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderGrey),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
          ],
        ),
        child: Column(
          spacing: 5.h,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: blog.author.avatarUrl != null
                      ? NetworkImage(blog.author.avatarUrl!)
                      : null,
                  child: blog.author.avatarUrl == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      blog.author.name,
                      style: textStyle_16BoldBlack().copyWith(
                        height: 1.2,
                        fontSize: 14.sp,
                      ),
                    ),
                    2.verticalSpace,
                    Text(
                      '${DateFormat.yMMMd().format(blog.createdAt)} · ${_readTime(blog.content)} min read',
                      style: textStyle_12LightGrey().copyWith(
                        color: AppColors.subtitles,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Divider(color: AppColors.borderGrey),
            Row(
              spacing: 10.w,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _previewText(blog.content),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: textStyle_12LightGrey(),
                      ),

                      8.verticalSpace,
                    ],
                  ),
                ),
                Container(
                  width: 130.w,
                  height: 100.h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: Colors.grey.shade200,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: blog.coverImage != null
                      ? Image.network(blog.coverImage!, fit: BoxFit.cover)
                      : Icon(Icons.broken_image),
                ),
              ],
            ),

            Row(
              children: [
                Container(
                  height: 30.h,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      '#${blog.category.smartCategoryCase()}',
                      style: textStyle_14RegularLinkBlue().copyWith(
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                ),

                const Spacer(),
                TextButton(
                  onPressed: () {
                    context.push('/blog/${blog.id}', extra: blog);
                  },
                  child: Text(
                    'Read More',
                    style: textStyle_14RegularLinkBlue(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
