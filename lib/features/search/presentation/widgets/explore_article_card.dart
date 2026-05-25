import 'package:Readme/core/utils/app_colors.dart';
import 'package:Readme/core/utils/app_image.dart';
import 'package:Readme/core/utils/quill_content_parser.dart';
import 'package:Readme/core/utils/text_style.dart';
import 'package:Readme/features/home_page/domain/entities/blog.dart';
import 'package:Readme/features/search/data/models/explore_article_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class ExploreArticleCard extends StatelessWidget {
  const ExploreArticleCard({
    super.key,
    required this.article,
  });

  final ExploreArticle article;

  @override
  Widget build(BuildContext context) {
    final authorNames = article.authors.map((a) => a.name).join(', ');
    final authorCount = article.authors.length;
    final hasCommunity = article.communityName != null &&
        article.communityName!.trim().isNotEmpty;

    return GestureDetector(
      onTap: () => context.push('/blog/${article.blog.id}', extra: article.blog),
      child: Container(
        padding: EdgeInsets.all(20.w),
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
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (hasCommunity)
                  _CommunityTag(
                    name: article.communityName!,
                    logoUrl: article.communityLogoUrl,
                  ),
                if (article.blog.category.isNotEmpty)
                  Text(
                    article.blog.category.toUpperCase(),
                    style: textStyle_14BoldLinkBlue().copyWith(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                      color: AppColors.linkBlue,
                    ),
                  ),
              ],
            ),
            SizedBox(height: 16.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AuthorAvatarStack(authors: article.authors),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authorNames,
                        style: textStyle_16BoldBlack().copyWith(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                      if (authorCount > 1) ...[
                        SizedBox(height: 4.h),
                        Text(
                          '$authorCount authors',
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
            SizedBox(height: 16.h),
            Text(
              article.blog.title,
              style: textStyle_16BoldBlack().copyWith(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 10.h),
            Text(
              parseQuillContent(article.blog.content),
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

class _CommunityTag extends StatelessWidget {
  const _CommunityTag({
    required this.name,
    this.logoUrl,
  });

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
        backgroundImage: imageProviderFromSource(author.avatarUrl),
        child: author.avatarUrl == null
            ? Icon(Icons.person, size: 18.r, color: Colors.grey)
            : null,
      );
    }

    final visible = authors.take(3).toList();
    final radius = 16.r;
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
                  backgroundImage:
                      imageProviderFromSource(visible[i].avatarUrl),
                  child: visible[i].avatarUrl == null
                      ? Icon(Icons.person,
                          size: radius, color: Colors.grey)
                      : null,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
