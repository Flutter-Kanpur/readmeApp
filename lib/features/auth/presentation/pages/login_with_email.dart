import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:Readme/core/utils/assets_path.dart';
import 'package:Readme/core/utils/text_style.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/widgets/gradient_background.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/textfield.dart';
import 'package:Readme/core/network/readme_supabase.dart';

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
  final supabase = ReadmeSupabase.client;

  void _showSnackBar(SnackBar snackBar) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }

  String _errorMessage(Object error) {
    if (error is AuthException) {
      final message = error.message.toLowerCase();
      if (message.contains('invalid login credentials') ||
          message.contains('invalid credentials')) {
        return 'Incorrect email or password. Please try again.';
      }
      if (message.contains('email not confirmed')) {
        return 'Please confirm your email before logging in.';
      }
      if (message.contains('failed host lookup') ||
          message.contains('socketexception') ||
          message.contains('network is unreachable')) {
        return 'No internet connection. Check your network and try again.';
      }
      return error.message;
    }

    final message = error.toString().toLowerCase();
    if (message.contains('failed host lookup') ||
        message.contains('socketexception') ||
        message.contains('network is unreachable') ||
        message.contains('clientexception')) {
      return 'No internet connection. Check your network and try again.';
    }

    return 'Unable to log in. Please try again.';
  }

  Future<void> _login() async {
    if (loading) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty) {
      _showSnackBar(
        const SnackBar(
          content: Text('Please enter your email address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (password.isEmpty) {
      _showSnackBar(
        const SnackBar(
          content: Text('Please enter your password'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => loading = true);
    try {
      await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;
      context.go('/home');
    } on AuthException catch (e) {
      _showSnackBar(
        SnackBar(
          content: Text(_errorMessage(e)),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      debugPrint(e.toString());
      _showSnackBar(
        SnackBar(
          content: Text(_errorMessage(e)),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => loading = false);
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
              SizedBox(height: 20.h),
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
        Image.asset(
          AssetsPath.brandImage,
          package: AssetsPath.package,
          height: 100.h,
        ),
        SizedBox(height: 12.h),
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
        behavior: HitTestBehavior.opaque,
        onTap: () {
          final email = _emailController.text.trim();
          context.push(
            '/forgot-password',
            extra: email.isEmpty ? null : email,
          );
        },
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 4.w),
          child: Text(
            "Forgot Password?",
            style: textStyle_16RegularLinkBlue(),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return PrimaryButton(
      loading: loading,
      text: 'Login',
      onPressed: _login,
    );
  }


  Widget _buildCreateAccountLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("New here? ", style: textStyle_16RegularBlack()),
        GestureDetector(
          onTap: () => context.push('/signup'),
          child: Text(
            "Create an account",
            style: textStyle_16RegularLinkBlue(),
          ),
        ),
      ],
    );
  }
}
