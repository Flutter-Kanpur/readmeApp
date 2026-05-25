import 'package:Readme/core/utils/text_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:Readme/core/utils/app_colors.dart';
import 'package:Readme/core/utils/app_image.dart';
import 'package:Readme/core/utils/quill_content_parser.dart';
import 'package:Readme/features/blog_detail/presentation/widgets/blog_content_viewer.dart';
import 'package:Readme/features/home_page/domain/entities/blog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BlogDetailScreen extends StatelessWidget {
  final Blog blog;

  const BlogDetailScreen({super.key, required this.blog});

  String _storagePublicUrl(String path) {
    return Supabase.instance.client.storage
        .from('blog_images')
        .getPublicUrl(path);
  }

  String? _resolveCoverImageUrl() {
    return resolveBlogImageUrl(
      blog.coverImage,
      storagePathToUrl: _storagePublicUrl,
    ) ??
        extractFirstImageUrl(
          blog.content,
          storagePathToUrl: _storagePublicUrl,
        );
  }

  @override
  Widget build(BuildContext context) {
    final coverImageUrl = _resolveCoverImageUrl();

    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.white,
          body: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                    child: InkWell(
                      onTap: () => context.pop(),
                      borderRadius: BorderRadius.circular(999),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 8.h,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.arrow_back,
                              size: 16.sp,
                              color: AppColors.bgBlue,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              'Back to Explore',
                              style: textStyle_14RegularBlack().copyWith(
                                fontSize: 14.sp,
                                color: AppColors.linkBlue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 40.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        blog.title,
                        softWrap: true,
                        style: GoogleFonts.poppins(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.black,
                          height: 1.25,
                          // letterSpacing: 1,
                        ),
                      ),
                      if (coverImageUrl != null) ...[
                        SizedBox(height: 20.h),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12.r),
                          child: AppImage(
                            source: coverImageUrl,
                            width: double.infinity,
                            height: 240.h,
                            fit: BoxFit.cover,
                            placeholder: Container(
                              width: double.infinity,
                              height: 240.h,
                              color: Colors.grey.shade100,
                              alignment: Alignment.center,
                              child: const CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                      ],
                      SizedBox(height: 20.h),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 20.r,
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage: imageProviderFromSource(
                              blog.author.avatarUrl,
                            ),
                            child: blog.author.avatarUrl == null
                                ? Icon(Icons.person, size: 20.r)
                                : null,
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  blog.author.name,
                                  style: GoogleFonts.ptSans(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.black,
                                    height: 1.2,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  DateFormat('EEE MMM d yyyy')
                                      .format(blog.createdAt),
                                  style: GoogleFonts.poppins(
                                    fontSize: 13.sp,
                                    color: AppColors.subtitles,
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 24.h),
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: AppColors.borderGrey,
                      ),
                      SizedBox(height: 20.h),
                      BlogContentViewer(
                        content: blog.content,
                        imageUrls: blog.imageUrls,
                        excludeImageUrl: coverImageUrl,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
