import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:readme_blogapp/core/utils/assets_path.dart';

class BottomNavbar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });
  @override
  Widget build(BuildContext) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(40.r),
      child: Container(
        height: 75.h,
        color: Color(0xff1F1F1F),
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _navItem(AssetsPath.home, 0),
            _navItem(AssetsPath.search, 1),
            _navItem(AssetsPath.create, 2),
            _navItem(AssetsPath.trending, 3),
            _navItem(AssetsPath.profile, 4),
          ],
        ),
      ),
    );
  }

  Widget _navItem(String icon, int index) {
    final isSelected = currentIndex == index;

    return Padding(
      padding: EdgeInsets.only(left: 0.sp, right: 0.sp),
      child: GestureDetector(
        onTap: () => onTap(index),
        child: Container(
          height: 45.h,
          padding: isSelected
              ? EdgeInsets.symmetric(horizontal: 20.sp)
              : EdgeInsets.symmetric(horizontal: 0.sp, vertical: 0.sp),
          decoration: BoxDecoration(
            color: isSelected ? Color(0xff363636) : Colors.transparent,
            borderRadius: BorderRadius.circular(40.r),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SvgPicture.asset(
                icon,
                height: 0.03.sh,
                width: 0.03.sw,
                colorFilter: ColorFilter.mode(
                  isSelected ? Color(0xffFFFFFF) : Color(0xffA8A7A8),
                  BlendMode.srcIn,
                ),
              ),

              if (isSelected && index != 2) ...[
                10.horizontalSpace,
                Text(
                  _labelForIndex(index),
                  style: TextStyle(
                    color: const Color(0xffFFFFFF),
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _labelForIndex(int index) {
    switch (index) {
      case 0:
        return 'Home';
      case 1:
        return 'Search';
      case 2:
        return 'Create';
      case 3:
        return 'Trending';
      case 4:
        return 'Profile';
      default:
        return '';
    }
  }
}
