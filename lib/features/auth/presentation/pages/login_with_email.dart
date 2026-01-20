import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../shared/widgets/gradient_background.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../../../shared/widgets/textfield.dart';

class LoginWithEmail extends StatefulWidget {
  const LoginWithEmail({super.key});

  @override
  State<LoginWithEmail> createState() => _LoginWithEmailState();
}

class _LoginWithEmailState extends State<LoginWithEmail> {
  late TextEditingController _emailController;
  late TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          children: [
            Spacer(flex: 8),
            _buildHeader(),
            SizedBox(height: 32.h),
            _buildEmailField(),
            SizedBox(height: 16.h),
            _buildPasswordField(),
            SizedBox(height: 12.h),
            _buildForgotPasswordLink(),
            SizedBox(height: 20.h),
            _buildLoginButton(),
            SizedBox(height: 20.h),
            _buildCreateAccountLink(),
            Spacer(flex: 1),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        5.horizontalSpace,
        Text(
          "Welcome back",
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 12.h),
        Text(
          "Log in to continue where you left off.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF6D6D6D), fontSize: 16, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return CustomTextField(
      text: "Email Address/Username",
      hintColor: Color(0xFFD6D6D6),
      hintFontSize: 16,
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      isPassword: false,
    );
  }

  Widget _buildPasswordField() {
    return CustomTextField(
      text: "Password",
      hintColor: Color(0xFFD6D6D6),
      hintFontSize: 16, 
      controller: _passwordController,
      isPassword: true,
      enablePasswordToggle: true,
    );
  }

  Widget _buildForgotPasswordLink() {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: () {
          // Handle forgot password
        },
        child: Text(
          "Forgot Password?",
          style: TextStyle(
            color: const Color(0xff4A90E2),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return GradientButton(
      text: "Login",
      fontSize: 16,
      onTap: () {
        // Handle login
      },
      height: 55.h,
      width: double.infinity,
    );
  }

  Widget _buildCreateAccountLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "New here? ",
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        GestureDetector(
          onTap: () {
            // Handle navigate to sign up
          },
          child: Text(
            "Create an account",
            style: TextStyle(
              color: const Color(0xff4A90E2),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
