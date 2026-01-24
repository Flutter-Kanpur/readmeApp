import 'package:Readme/core/utils/string_extensions.dart';
import 'package:Readme/core/utils/text_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/app_colors.dart';
import '../../domain/entities/blog.dart';

class BlogCard extends StatelessWidget {
  final Blog blog;

  const BlogCard({super.key, required this.blog});

  int _readTime(String text) {
    final words = text.split(' ').length;
    return (words / 200).ceil();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
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
                  Text(blog.author.name, style: textStyle_16BoldBlack()),
                  2.verticalSpace,
                  Text(
                    '${DateFormat.yMMMd().format(blog.createdAt)} · ${_readTime(blog.content)} min read',
                    style: textStyle_12RegularGrey(),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            spacing: 10.w,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      blog.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textStyle_16BoldBlack().copyWith(height: 1.2),
                    ),
                    8.verticalSpace,
                    Text(
                      blog.content,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: textStyle_14RegularGrey(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: Colors.grey.shade200,
                ),
                clipBehavior: Clip.antiAlias,
                child: blog.coverImage != null
                    ? Image.network(blog.coverImage!, fit: BoxFit.cover)
                    : Icon(Icons.broken_image),
              ),
              const SizedBox(width: 10),
            ],
          ),

          const SizedBox(height: 10),
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
                    style: textStyle_14BoldLinkBlue(),
                  ),
                ),
              ),

              const Spacer(),
              TextButton(
                onPressed: () {
                  // navigate to blog detail
                },
                child: Text('Read More →', style: textStyle_16BoldLinkBlue()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
