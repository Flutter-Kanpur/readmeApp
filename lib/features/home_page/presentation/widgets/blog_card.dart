import 'package:Readme/core/utils/quill_content_parser.dart';
import 'package:Readme/core/utils/text_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/cache/blog_like_cache.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_image.dart';
import '../../../blog_detail/presentation/widgets/blog_support_button.dart';
import '../../../blog_detail/presentation/widgets/blog_view_count.dart';
import '../../domain/entities/blog.dart';

class BlogCard extends StatelessWidget {
  final Blog blog;

  const BlogCard({super.key, required this.blog});

  String? _previewText(String content) {
    final preview = parseQuillContent(content).trim();
    return preview.isEmpty ? null : preview;
  }

  @override
  Widget build(BuildContext context) {
    final authors = blog.allAuthors;
    final hasCoauthors = authors.length > 1;
    final authorNames = authors.map((a) => a.name).join(', ');
    final hasCommunity =
        blog.communityName != null && blog.communityName!.trim().isNotEmpty;
    final hasCategory = blog.category.isNotEmpty;

    final preview = _previewText(blog.content);

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
            if (hasCommunity || hasCategory) ...[
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (hasCommunity)
                    _CommunityTag(
                      name: blog.communityName!,
                      logoUrl: blog.communityLogoUrl,
                    ),
                  if (hasCategory)
                    Text(
                      blog.category.toUpperCase(),
                      style: textStyle_14BoldLinkBlue().copyWith(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                        color: AppColors.linkBlue,
                      ),
                    ),
                ],
              ),
              SizedBox(height: 14.h),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _AuthorAvatarStack(authors: authors),
                SizedBox(width: hasCoauthors ? 12.w : 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        authorNames,
                        style: textStyle_16BoldBlack().copyWith(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (hasCoauthors) ...[
                        SizedBox(height: 2.h),
                        Text(
                          '${authors.length} authors',
                          style: textStyle_12RegularGrey().copyWith(
                            fontSize: 12.sp,
                            color: AppColors.subtitles,
                          ),
                        ),
                      ],
                    ],
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
            if (preview != null) ...[
              SizedBox(height: 10.h),
              Text(
                preview,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: textStyle_14RegularGrey().copyWith(
                  fontSize: 14.sp,
                  color: AppColors.subtitles,
                  height: 1.45,
                ),
              ),
            ],
            SizedBox(height: 14.h),
            Row(
              children: [
                BlogSupportButton(
                  blogId: blog.id,
                  initialLikeCount: blog.likeCount,
                  initialIsLiked: BlogLikeCache.instance.isLiked(blog.id),
                  compact: true,
                ),
                SizedBox(width: 12.w),
                BlogViewCount(count: blog.viewCount),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CommunityTag extends StatelessWidget {
  const _CommunityTag({required this.name, this.logoUrl});

  final String name;
  final String? logoUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F0FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (logoUrl != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4.r),
              child: AppImage(
                source: logoUrl,
                width: 16.w,
                height: 16.w,
                fit: BoxFit.cover,
                placeholder: SizedBox(width: 16.w, height: 16.w),
              ),
            ),
            SizedBox(width: 6.w),
          ],
          Text(
            name.toUpperCase(),
            style: textStyle_12RegularGrey().copyWith(
              fontSize: 10.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: AppColors.linkBlue,
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthorAvatarStack extends StatelessWidget {
  const _AuthorAvatarStack({required this.authors});

  final List<Author> authors;

  @override
  Widget build(BuildContext context) {
    if (authors.isEmpty) {
      return CircleAvatar(
        radius: 16.r,
        backgroundColor: Colors.grey.shade200,
        child: Icon(Icons.person, size: 18.r, color: Colors.grey),
      );
    }

    if (authors.length == 1) {
      final author = authors.first;
      return CircleAvatar(
        radius: 16.r,
        backgroundColor: Colors.grey.shade200,
        backgroundImage: imageProviderFromSource(
          author.avatarUrl,
          width: 32,
          height: 32,
        ),
        child: author.avatarUrl == null
            ? Icon(Icons.person, size: 18.r, color: Colors.grey)
            : null,
      );
    }

    final visible = authors.take(3).toList();
    final radius = 14.r;
    final diameter = radius * 2;
    final overlap = diameter * 0.4;
    final stride = diameter - overlap;
    final width = diameter + (visible.length - 1) * stride;

    return SizedBox(
      width: width,
      height: diameter,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (int i = 0; i < visible.length; i++)
            Positioned(
              left: i * stride,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: CircleAvatar(
                  radius: radius - 1.5,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: imageProviderFromSource(
                    visible[i].avatarUrl,
                    width: 28,
                    height: 28,
                  ),
                  child: visible[i].avatarUrl == null
                      ? Icon(Icons.person, size: radius, color: Colors.grey)
                      : null,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
