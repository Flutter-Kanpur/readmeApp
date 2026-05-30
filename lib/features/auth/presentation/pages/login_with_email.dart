import 'package:Readme/features/home_page/presentation/pages/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:Readme/core/utils/text_style.dart';
import 'package:Readme/features/auth/presentation/pages/signup_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/widgets/gradient_background.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../../../shared/widgets/textfield.dart';

class LoginWithEmail extends StatefulWidget {
  const LoginWithEmail({super.key});

  @override
  State<LoginWithEmail> createState() => _LoginWithEmailState();
}

class _LoginWithEmailState extends State<LoginWithEmail> {
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _emailFieldKey = GlobalKey();
  final _passwordFieldKey = GlobalKey();

  bool loading = false;
  final supabase = Supabase.instance.client;

  void login() async {
    setState(() {
      loading = true;
    });
    try {
      final result = await supabase.auth.signInWithPassword(
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: GradientBackground(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Spacer(flex: 8),
              _buildHeader(),
              SizedBox(height: 32.h),
              _buildEmailField(),
              SizedBox(height: 12.h),
              _buildPasswordField(),
              SizedBox(height: 12.h),
              _buildForgotPasswordLink(),
              loading
                  ? Center(child: CircularProgressIndicator())
                  : SizedBox(height: 20.h),
              _buildLoginButton(),
              SizedBox(height: 20.h),
              _buildCreateAccountLink(),
              Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        5.horizontalSpace,
        Text("Welcome back", style: textStyle_24BoldBlack()),
        SizedBox(height: 12.h),
        Text(
          "Log in to continue where you left off.",
          textAlign: TextAlign.center,
          style: textStyle_16RegularGrey(),
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return Container(
      key: _emailFieldKey,
      child: CustomTextField(
        text: "Email Address/Username",
        showBorder: _emailFocusNode.hasFocus,
        borderColor: _emailFocusNode.hasFocus
            ? Colors.blue
            : Colors.transparent,
        fillColor: _emailFocusNode.hasFocus
            ? Colors.transparent
            : const Color(0xFFF6F6F6),
        controller: _emailController,
        focusNode: _emailFocusNode,
        keyboardType: TextInputType.emailAddress,
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      key: _passwordFieldKey,
      child: CustomTextField(
        showBorder: _passwordFocusNode.hasFocus,
        fillColor: _passwordFocusNode.hasFocus
            ? Colors.transparent
            : const Color(0xFFF6F6F6),
        borderColor: _passwordFocusNode.hasFocus
            ? Colors.blue
            : Colors.transparent,
        text: "Password",
        controller: _passwordController,
        focusNode: _passwordFocusNode,
        isPassword: true,
      ),
    );
  }
  Widget _buildForgotPasswordLink() {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: () {
          // Handle forgot password
        },
        child: Text("Forgot Password?", style: textStyle_16RegularLinkBlue()),
      ),
    );
  }

  Widget _buildLoginButton() {
    return GradientButton(
      loading: loading,
      text: "Login",
      fontSize: 16,
      onTap: () async {
        try {
          await supabase.auth.signInWithPassword(
            email: _emailController.text,
            password: _passwordController.text,
          );

          if (!context.mounted) return;
          context.go('/home');
        } catch (e) {
          debugPrint(e.toString());
        }
      },
      height: 55.h,
      width: double.infinity,
    );
  }


  Widget _buildCreateAccountLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("New here? ", style: textStyle_16RegularBlack()),
        GestureDetector(
          onTap: () {
            // Handle navigate to sign up
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SignUpScreen()),
            );
          },
          child: Text(
            "Create an account",
            style: textStyle_16RegularLinkBlue(),
          ),
        ),
      ],
    );
  }
}
