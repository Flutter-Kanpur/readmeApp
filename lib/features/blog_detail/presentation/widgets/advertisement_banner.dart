import 'package:Readme/core/utils/text_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AdvertisementBanner extends StatelessWidget {
  const AdvertisementBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 280.h,
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      alignment: Alignment.center,
      child: Text(
        'ADVERTISEMENT',
        style: textStyle_12RegularGrey().copyWith(
          fontSize: 12.sp,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
