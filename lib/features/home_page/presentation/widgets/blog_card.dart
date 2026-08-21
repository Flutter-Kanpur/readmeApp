import 'package:Readme/core/providers/supabase_providers.dart';
import 'package:Readme/core/utils/app_colors.dart';
import 'package:Readme/core/utils/app_image.dart';
import 'package:Readme/core/utils/quill_content_parser.dart';
import 'package:Readme/core/utils/text_style.dart';
import 'package:Readme/features/blog_detail/presentation/widgets/blog_support_button.dart';
import 'package:Readme/features/blog_detail/presentation/widgets/blog_view_count.dart';
import 'package:Readme/features/home_page/domain/entities/blog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class BlogCard extends ConsumerWidget {
  final Blog blog;

  const BlogCard({super.key, required this.blog});

  String? _previewText(String content) {
    final preview = parseQuillContent(content).trim();
    return preview.isEmpty ? null : preview;
  }

  String? _coverUrl(WidgetRef ref) {
    final client = ref.read(supabaseClientProvider);
    String storagePublicUrl(String path) {
      return client.storage.from('blog_images').getPublicUrl(path);
    }

    return resolveBlogImageUrl(
          blog.coverImage,
          storagePathToUrl: storagePublicUrl,
        ) ??
        extractFirstImageUrl(
          blog.content,
          storagePathToUrl: storagePublicUrl,
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authors = blog.allAuthors;
    final hasCoauthors = authors.length > 1;
    final authorNames = authors.map((a) => a.name).join(', ');
    final hasCommunity =
        blog.communityName != null && blog.communityName!.trim().isNotEmpty;
    final hasCategory = blog.category.isNotEmpty;
    final preview = _previewText(blog.content);
    final coverUrl = _coverUrl(ref);

    return GestureDetector(
      onTap: () => context.push('/blog/${blog.id}', extra: blog),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE8E8E8)),
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
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
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
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
                          fontWeight: FontWeight.w700,
                          height: 1.25,
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
            if (coverUrl != null) ...[
              SizedBox(height: 14.h),
              ClipRRect(
                borderRadius: BorderRadius.circular(18.r),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: AppImage(
                    source: coverUrl,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: Container(color: Colors.grey.shade100),
                  ),
                ),
              ),
            ],
            SizedBox(height: 14.h),
            Text(
              blog.title,
              style: textStyle_16BoldBlack().copyWith(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                height: 1.3,
                color: AppColors.black,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            if (preview != null) ...[
              SizedBox(height: 8.h),
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
                  compact: true,
                ),
                SizedBox(width: 14.w),
                BlogViewCount(blogId: blog.id, count: blog.viewCount),
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
      padding: EdgeInsets.fromLTRB(6.w, 5.h, 10.w, 5.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F0FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipOval(
            child: AppImage(
              source: logoUrl,
              width: 18.w,
              height: 18.w,
              fit: BoxFit.cover,
              placeholder: Container(
                width: 18.w,
                height: 18.w,
                color: const Color(0xFFE4DEFF),
                alignment: Alignment.center,
                child: Icon(
                  Icons.groups_outlined,
                  size: 11.sp,
                  color: AppColors.linkBlue,
                ),
              ),
            ),
          ),
          SizedBox(width: 6.w),
          Text(
            name.toUpperCase(),
            style: textStyle_12RegularGrey().copyWith(
              fontSize: 10.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.35,
              color: const Color(0xFF5B4BDB),
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
        radius: 18.r,
        backgroundColor: Colors.grey.shade200,
        child: Icon(Icons.person, size: 18.r, color: Colors.grey),
      );
    }

    if (authors.length == 1) {
      final author = authors.first;
      return CircleAvatar(
        radius: 18.r,
        backgroundColor: Colors.grey.shade200,
        backgroundImage: imageProviderFromSource(
          author.avatarUrl,
          width: 36,
          height: 36,
        ),
        child: author.avatarUrl == null
            ? Icon(Icons.person, size: 18.r, color: Colors.grey)
            : null,
      );
    }

    final visible = authors.take(3).toList();
    final radius = 16.r;
    final diameter = radius * 2;
    final overlap = diameter * 0.38;
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
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: CircleAvatar(
                  radius: radius - 2,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: imageProviderFromSource(
                    visible[i].avatarUrl,
                    width: 32,
                    height: 32,
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
