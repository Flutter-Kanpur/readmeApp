import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/blog.dart';

class BlogCard extends StatelessWidget {
  final Blog blog;

  const BlogCard({
    super.key,
    required this.blog,
  });

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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          )
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
                  Text(blog.author.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                    '${DateFormat.yMMMd().format(blog.createdAt)} · ${_readTime(blog.content)} min read',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              )
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
                      style:  TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      blog.content,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style:  TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12.sp,
                      fontWeight: FontWeight.normal,
                    ),
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
                color: Colors.grey.shade200, // for visibility
              ),
              child: blog.coverImage != null
                  ? Image.network(blog.coverImage!)
                  : Icon(Icons.broken_image),
              ),
              const SizedBox(width: 10),
            ],
          ),

          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {},
              child: const Text('Read more →'),
            ),
          ),
        ],
      ),
    );
  }
}
