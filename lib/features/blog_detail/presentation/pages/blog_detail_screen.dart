import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:Readme/core/utils/string_extensions.dart';
import 'package:Readme/core/utils/text_style.dart';
import 'package:Readme/core/utils/app_colors.dart';
import 'package:Readme/features/home_page/domain/entities/blog.dart';

class BlogDetailScreen extends StatelessWidget {
  final Blog blog;

  const BlogDetailScreen({super.key, required this.blog});

  int _readTime(String text) {
    final words = text.split(' ').length;
    return (words / 200).ceil();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Back Navigation
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Row(
                      children: [
                        const Icon(Icons.chevron_left, size: 24),
                        SizedBox(width: 4.w),
                        Text(
                          'Back to home',
                          style: textStyle_14RegularBlack(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Image/Placeholder
                    Container(
                      width: double.infinity,
                      height: 200.h,
                      color: Colors.grey.shade200,
                      child: blog.coverImage != null
                          ? Image.network(
                              blog.coverImage!,
                              fit: BoxFit.cover,
                            )
                          : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    blog.category.smartCategoryCase(),
                                    style: TextStyle(
                                      fontSize: 32.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  SizedBox(height: 8.h),
                                  Text(
                                    'qawemre',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                    // Content Section
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category Tag
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 6.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Text(
                              blog.category.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800,
                              ),
                            ),
                          ),
                          SizedBox(height: 16.h),
                          // Title
                          Text(
                            blog.title,
                            style: TextStyle(
                              fontSize: 24.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              height: 1.3,
                            ),
                          ),
                          SizedBox(height: 20.h),
                          // Author Information
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 24.r,
                                backgroundImage: blog.author.avatarUrl != null
                                    ? NetworkImage(blog.author.avatarUrl!)
                                    : null,
                                child: blog.author.avatarUrl == null
                                    ? const Icon(Icons.person)
                                    : null,
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      blog.author.name,
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      '${DateFormat.yMMMd().format(blog.createdAt)} • ${_readTime(blog.content)} min read',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Follow Button
                              ElevatedButton(
                                onPressed: () {
                                  // TODO: Implement follow functionality
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 20.w,
                                    vertical: 10.h,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20.r),
                                  ),
                                ),
                                child: Text(
                                  'Follow',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 30.h),
                          // Article Content
                          _buildArticleContent(blog.content),
                          SizedBox(height: 30.h),
                          // Tags Section
                          Wrap(
                            spacing: 8.w,
                            runSpacing: 8.h,
                            children: [
                              _buildTag('#Flutter'),
                              _buildTag('#Performance'),
                              _buildTag('#Dart'),
                            ],
                          ),
                          SizedBox(height: 100.h), // Space for bottom interaction bar
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Bottom Interaction Bar
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildInteractionButton(
                    icon: Icons.thumb_up_outlined,
                    label: '1.2k',
                    onTap: () {
                      // TODO: Implement like functionality
                    },
                  ),
                  _buildInteractionButton(
                    icon: Icons.comment_outlined,
                    label: '48',
                    onTap: () {
                      // TODO: Implement comment functionality
                    },
                  ),
                  _buildInteractionButton(
                    icon: Icons.share_outlined,
                    label: '',
                    onTap: () {
                      // TODO: Implement share functionality
                    },
                  ),
                  _buildInteractionButton(
                    icon: Icons.bookmark_border,
                    label: '',
                    onTap: () {
                      // TODO: Implement save functionality
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArticleContent(String content) {
    // Split content into paragraphs
    final paragraphs = content.split('\n\n').where((p) => p.trim().isNotEmpty).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: paragraphs.asMap().entries.map((entry) {
        final index = entry.key;
        final paragraph = entry.value.trim();
        
        // Check if paragraph contains code-like content
        if (paragraph.contains('//') && paragraph.contains('const') && 
            (paragraph.contains('Container') || paragraph.contains('Widget'))) {
          // Render as code block
          return Padding(
            padding: EdgeInsets.only(bottom: 20.h),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: SelectableText(
                paragraph,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontFamily: 'monospace',
                  color: Colors.white,
                  height: 1.5,
                ),
              ),
            ),
          );
        }
        
        // Check if it's a numbered section (starts with number and period)
        final numberedMatch = RegExp(r'^(\d+\.\s+)(.+)$').firstMatch(paragraph);
        if (numberedMatch != null) {
          final numberPart = numberedMatch.group(1)!;
          final textPart = numberedMatch.group(2)!;
          
          return Padding(
            padding: EdgeInsets.only(bottom: 20.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  numberPart + textPart.split('\n').first,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                if (textPart.contains('\n'))
                  Padding(
                    padding: EdgeInsets.only(top: 8.h),
                    child: Text(
                      textPart.substring(textPart.indexOf('\n') + 1),
                      style: TextStyle(
                        fontSize: 15.sp,
                        color: Colors.black87,
                        height: 1.6,
                      ),
                    ),
                  ),
              ],
            ),
          );
        }
        
        // Regular paragraph
        return Padding(
          padding: EdgeInsets.only(bottom: 16.h),
          child: Text(
            paragraph,
            style: TextStyle(
              fontSize: 15.sp,
              color: Colors.black87,
              height: 1.6,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTag(String tag) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        tag,
        style: TextStyle(
          fontSize: 12.sp,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  Widget _buildInteractionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24.sp, color: Colors.grey.shade700),
          if (label.isNotEmpty) ...[
            SizedBox(width: 6.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
