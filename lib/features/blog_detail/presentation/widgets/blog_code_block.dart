import 'package:Readme/core/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class BlogCodeBlock extends StatelessWidget {
  const BlogCodeBlock({super.key, required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    if (code.trim().isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: 12.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(4.r),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Text(
          code,
          style: GoogleFonts.sourceCodePro(
            fontSize: 14.sp,
            height: 1.4,
            color: AppColors.black,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }
}
