import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TabsContainer extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;
  const TabsContainer({
    super.key,
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 35.h,
        padding: EdgeInsets.symmetric(horizontal: 16.sp),
        decoration: BoxDecoration(
          color: isSelected?Colors.black:Colors.white,
          borderRadius: BorderRadius.circular(30.r),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            color: isSelected?Colors.white:Colors.grey.shade700,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
