import 'package:Readme/core/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onCtaTap,
    this.hasDraft = false,
    this.isDraftActive = false,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onCtaTap;
  final bool hasDraft;
  final bool isDraftActive;

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

  int _navIndexFor(int barIndex) {
    if (barIndex < 2) return barIndex;
    return barIndex - 1;
  }

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < 5; i++)
                if (i == 2)
                  Expanded(
                    child: _DraftCtaButton(
                      onTap: onCtaTap,
                      hasDraft: hasDraft,
                      isActive: isDraftActive,
                    ),
                  )
                else
                  Expanded(
                    child: _NavItem(
                      data: _items[_navIndexFor(i)],
                      isSelected: currentIndex == _navIndexFor(i),
                      onTap: () => onTap(_navIndexFor(i)),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavBarSlot extends StatelessWidget {
  const _NavBarSlot({
    required this.icon,
    required this.label,
    required this.labelColor,
    required this.onTap,
  });

  final Widget icon;
  final String label;
  final Color labelColor;
  final VoidCallback onTap;

  static double get iconSlotHeight => 28.h;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 6.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: iconSlotHeight,
                child: Center(child: icon),
              ),
              SizedBox(height: 4.h),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'ProductSans',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: labelColor,
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

class _DraftCtaButton extends StatelessWidget {
  const _DraftCtaButton({
    required this.onTap,
    required this.hasDraft,
    this.isActive = false,
  });

  final VoidCallback onTap;
  final bool hasDraft;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return _NavBarSlot(
      onTap: onTap,
      label: 'Draft',
      labelColor: isActive ? AppColors.linkBlue : AppColors.subtitles,
      icon: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: 28.w,
            height: 28.w,
            decoration: BoxDecoration(
              color: AppColors.black,
              shape: BoxShape.circle,
              border: isActive
                  ? Border.all(color: AppColors.linkBlue, width: 2)
                  : null,
            ),
            child: Icon(
              Icons.edit_outlined,
              size: 16.sp,
              color: Colors.white,
            ),
          ),
          if (hasDraft)
            Positioned(
              top: -1,
              right: -1,
              child: Container(
                width: 8.w,
                height: 8.w,
                decoration: BoxDecoration(
                  color: AppColors.linkBlue,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            ),
        ],
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

    return _NavBarSlot(
      onTap: onTap,
      label: data.label,
      labelColor: color,
      icon: Icon(
        isSelected ? data.activeIcon : data.icon,
        size: 24.sp,
        color: color,
      ),
    );
  }
}
