import 'package:Readme/core/utils/app_colors.dart';
import 'package:Readme/core/utils/assets_path.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
    _NavItemData(label: 'Home', assetPath: AssetsPath.homeNaveIcon),
    _NavItemData(label: 'Explore', assetPath: AssetsPath.exploreIcon),
    _NavItemData(label: 'Community', assetPath: AssetsPath.communityIcon),
    _NavItemData(label: 'Profile', assetPath: AssetsPath.profileNaveIcon),
  ];

  int _navIndexFor(int barIndex) {
    if (barIndex < 2) return barIndex;
    return barIndex - 1;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0XFFFAFCFF),
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
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
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
    final color = isActive ? AppColors.linkBlue : AppColors.subtitles;

    return _NavBarSlot(
      onTap: onTap,
      label: 'Draft',
      labelColor: color,
      icon: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          SvgPicture.asset(
            AssetsPath.draftIcon,
            width: 22.sp,
            height: 22.sp,
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          ),
          if (hasDraft)
            Positioned(
              top: -2,
              right: -4,
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
    required this.assetPath,
  });

  final String label;
  final String assetPath;
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
      icon: SvgPicture.asset(
        data.assetPath,
        width: 25.sp,
        height: 25.sp,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      ),
    );
  }
}
