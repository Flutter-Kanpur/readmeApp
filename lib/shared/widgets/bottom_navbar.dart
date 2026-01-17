import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:readme_blogapp/core/utils/assets_path.dart';

class BottomNavbar extends StatelessWidget{
  final int currentIndex;
  final ValueChanged<int> onTap;

const BottomNavbar({
  super.key,
  required this.currentIndex,
  required this.onTap,
}) ;
@override
  Widget build(BuildContext){
  return Padding(padding: const EdgeInsets.symmetric(horizontal: 20.0,vertical: 10.0),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(30.0),
      child: Container(
        color: Color(0xff1F1F1F),
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(AssetsPath.home, 0),
            _navItem(AssetsPath.search, 1),
            _navItem(AssetsPath.create, 2),
            _navItem(AssetsPath.trending, 3),
            _navItem(AssetsPath.profile, 4),
          ],
        ),
      ),
    ),
  );

  }
  Widget _navItem(String icon, int index) {
    final isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xff363636) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            SvgPicture.asset(
            icon,
            height: 22,
            colorFilter: ColorFilter.mode(
              isSelected ? Color(0xffFFFFFF) : Color(0xffA8A7A8),
              BlendMode.srcIn,
            ),
          ),

        ]),
      ),
    );
  }

}
