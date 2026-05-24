import 'package:Readme/core/utils/app_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BlogInlineImage extends StatelessWidget {
  const BlogInlineImage({super.key, required this.source});

  final String source;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width - 48.w;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.r),
        child: SizedBox(
          width: width,
          child: AppImage(
            source: source,
            width: width,
            fit: BoxFit.fitWidth,
            placeholder: Container(
              width: width,
              height: 220.h,
              color: Colors.grey.shade100,
              alignment: Alignment.center,
              child: const CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      ),
    );
  }
}
