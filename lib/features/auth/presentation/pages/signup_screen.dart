import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:Readme/core/utils/app_colors.dart';
import 'package:Readme/core/utils/text_style.dart';
import 'package:Readme/features/auth/presentation/pages/login_with_email.dart';
import 'package:Readme/features/auth/presentation/pages/login_with_google.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/widgets/gradient_background.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../../../shared/widgets/textfield.dart';
import '../../../home_page/home_screen.dart';

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
  bool loading = false;
  final supabase = Supabase.instance.client;

  createAccount() async {
    setState(() {
      loading = true;
    });
    try {
      final result = await supabase.auth.signUp(
        email: _emailController.text,
        password: _passwordController.text,
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
        (context) => false,
      );
    } catch (e) {
      print(e.toString());
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

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
        Text("Create your account", style: textStyle_24BoldBlack()),
        15.verticalSpace,
        Text(
          "Join Flutter Kanpur and be part of the\ncommunity.",
          textAlign: TextAlign.center,
          style: textStyle_16RegularGrey(),
        ),
        22.verticalSpace,
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
      hintColor: AppColors.subtitles,
      hintFontSize: 16,
    );
  }

  Widget _buildEmailField() {
    return CustomTextField(
      text: "Email Address",
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      isPassword: false,
      hintColor: AppColors.subtitles,
      hintFontSize: 16,
    );
  }

  Widget _buildCreatePasswordField() {
    return CustomTextField(
      text: "Create Password",
      controller: _passwordController,
      isPassword: true,
      enablePasswordToggle: true,
      hintColor: AppColors.subtitles,
      hintFontSize: 16,
    );
  }

  Widget _buildConfirmPasswordField() {
    return CustomTextField(
      text: "Confirm Password",
      controller: _confirmPasswordController,
      isPassword: true,
      enablePasswordToggle: true,
      hintColor: AppColors.subtitles,
      hintFontSize: 16,
    );
  }

  Widget _buildCreateAccountButton() {
    return GradientButton(
      text: "Create account",
      fontSize: 16,
      onTap: () {
        // Handle account creation
        createAccount();
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
              style: textStyle_16RegularBlack(),
            ),
            GestureDetector(
              onTap: () {
                // Handle navigate to login
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginWithEmail()),
                );
              },
              child: Text("Log in", style: textStyle_16RegularLinkBlue()),
            ),
          ],
        ),
      ],
    );
  }
}
