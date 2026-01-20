import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../shared/widgets/gradient_background.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../../../shared/widgets/textfield.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(),
              _buildForm(),
              _buildCreateAccountButton(),
              _buildLoginLink(),
              SizedBox(height: 30.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        SizedBox(height: 280.h),
        Text(
          "Create your account",
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 15.h),
        Text(
          "Join Flutter Kanpur and be part of the\ncommunity.",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF6D6D6D),
            fontSize: 16,
            height: 1.5,
            fontWeight: FontWeight.w400,
          ),
        ),
        SizedBox(height: 22.h),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      children: [
        _buildUsernameField(),
        SizedBox(height: 16.h),
        _buildEmailField(),
        SizedBox(height: 16.h),
        _buildCreatePasswordField(),
        SizedBox(height: 16.h),
        _buildConfirmPasswordField(),
        SizedBox(height: 30.h),
      ],
    );
  }

  Widget _buildUsernameField() {
    return CustomTextField(
      text: "Username",
      controller: _usernameController,
      isPassword: false,
      hintColor: Color(0xFFD6D6D6),
      hintFontSize: 16,
    );
  }

  Widget _buildEmailField() {
    return CustomTextField(
      text: "Email Address",
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      isPassword: false,
      hintColor: Color(0xFFD6D6D6),
      hintFontSize: 16,
    );
  }

  Widget _buildCreatePasswordField() {
    return CustomTextField(
      text: "Create Password",
      controller: _passwordController,
      isPassword: true,
      enablePasswordToggle: true,
      hintColor: Color(0xFFD6D6D6),
      hintFontSize: 16,
    );
  }

  Widget _buildConfirmPasswordField() {
    return CustomTextField(
      text: "Confirm Password",
      controller: _confirmPasswordController,
      isPassword: true,
      enablePasswordToggle: true,
      hintColor: Color(0xFFD6D6D6),
      hintFontSize: 16,
    );
  }

  Widget _buildCreateAccountButton() {
    return GradientButton(
      text: "Create account",
      fontSize: 16,
      onTap: () {
        // Handle account creation
      },
      height: 55.h,
      width: double.infinity,
    );
  }

  Widget _buildLoginLink() {
    return Column(
      children: [
        SizedBox(height: 20.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Already have an account? ",
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            GestureDetector(
              onTap: () {
                // Handle navigate to login
              },
              child: Text(
                "Log in",
                style: TextStyle(
                  color: const Color(0xff4A90E2),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
