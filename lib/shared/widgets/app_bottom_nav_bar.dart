import 'package:Readme/core/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    _NavItemData(
      label: 'Home',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_outlined,
    ),
    _NavItemData(
      label: 'Community',
      icon: Icons.people_outline_rounded,
      activeIcon: Icons.people_outline_rounded,
    ),
    _NavItemData(
      label: 'Explore',
      icon: Icons.search,
      activeIcon: Icons.search,
    ),
    _NavItemData(
      label: 'Profile',
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_outline_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          child: Row(
            children: [
              for (var i = 0; i < _items.length; i++)
                Expanded(
                  child: _NavItem(
                    data: _items[i],
                    isSelected: currentIndex == i,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  const _NavItemData({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.data,
    required this.isSelected,
    required this.onTap,
  });

  final _NavItemData data;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.linkBlue : AppColors.subtitles;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 6.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? data.activeIcon : data.icon,
                size: 24.sp,
                color: color,
              ),
              SizedBox(height: 4.h),
              Text(
                data.label,
                style: TextStyle(
                  fontFamily: 'ProductSans',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: color,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
