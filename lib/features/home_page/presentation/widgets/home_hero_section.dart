import 'package:Readme/core/utils/app_colors.dart';
import 'package:Readme/core/utils/text_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HomeHeroSection extends StatelessWidget {
  const HomeHeroSection({
    super.key,
    this.onStartWriting,
    this.onExploreTopics,
  });

  final VoidCallback? onStartWriting;
  final VoidCallback? onExploreTopics;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'CONNECT WITH DESIGNERS, WRITERS, AND CREATIVES.',
            textAlign: TextAlign.center,
            style: textStyle_12RegularGrey().copyWith(
              fontSize: 8.sp,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
              height: 1.4,
            ),
          ),
          SizedBox(height: 18.h),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: textStyle_24BoldBlack().copyWith(
                fontSize: 35.sp,
                fontWeight: FontWeight.w700,
                height: 1.2,
                // letterSpacing: -0.5,
              ),
              children: const [
                TextSpan(text: 'A space where\ncommunities share their '),
                TextSpan(
                  text: 'journey',
                  style: TextStyle(color: AppColors.linkBlue),
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            'Readme is a reader-first community focused on learning, building, and growing together through articles, collaboration, and real-world design practice.',
            textAlign: TextAlign.center,
            style: textStyle_16RegularGrey().copyWith(
              fontSize: 12.sp,
              height: 1.5,
              color: AppColors.subtitles,
            ),
          ),
          SizedBox(height: 44.h),
          _HeroButton(
            label: 'Start Writing',
            backgroundColor: AppColors.black,
            textColor: Colors.white,
            onTap: onStartWriting,
          ),
          SizedBox(height: 8.h),
          _HeroButton(
            label: 'Explore Topics →',
            backgroundColor: Colors.white,
            textColor: AppColors.black,
            borderColor: Colors.grey.shade200,
            onTap: onExploreTopics,
          ),
        ],
      ),
    );
  }
}

class _HeroButton extends StatelessWidget {
  const _HeroButton({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.borderColor,
    this.onTap,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      elevation: 0,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(999),
            border: borderColor != null
                ? Border.all(color: borderColor!)
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 16.h),
            alignment: Alignment.center,
            child: Text(
              label,
              style: textStyle_16BoldBlack().copyWith(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
