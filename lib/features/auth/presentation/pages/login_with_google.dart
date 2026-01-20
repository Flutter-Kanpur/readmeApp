import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../shared/widgets/gradient_background.dart';
import '../../../../shared/widgets/gradient_button.dart';

class LoginWithGoogle extends StatelessWidget {
  const LoginWithGoogle({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          children: [
            Spacer(flex: 15),
            Text(
              "Let's you in",
              style: TextStyle(
                color: Colors.black,
                fontSize: 24.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              "Be part of a community that learns\nand builds together.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16.sp,
                height: 1.5,
              ),
            ),
            Spacer(flex: 1),

            // Google Button
            _buildSocialButton(
              onTap: () {},
              label: "Continue with Google",
              svgPath: "assets/icons/Google.svg",
            ),

            SizedBox(height: 12.h),

            // Email Button
            _buildSocialButton(
              onTap: () {},
              label: "Sign in with Email",
              svgPath: "assets/icons/phone.svg",
            ),

            SizedBox(height: 20.h),

            Row(
              children: [
                Expanded(child: Divider(color: Colors.grey.withOpacity(0.3))),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Text(
                    "OR",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: Colors.grey.withOpacity(0.3))),
              ],
            ),

            SizedBox(height: 20.h),

            // Create Account Button - takes full width with internal max width constraint
            GradientButton(
              text: "Create Account",
              onTap: () {},
              height: 55.h,
              width: double.infinity,
            ),

            Spacer(flex: 3),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required VoidCallback onTap,
    required String label,
    required String svgPath,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 55.h,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(svgPath, height: 20.h, width: 20.w),
            SizedBox(width: 12.w),
            Text(
              label,
              style: TextStyle(
                color: Colors.black,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
