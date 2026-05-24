import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:Readme/core/network/supabase_connectivity.dart';
import 'package:Readme/core/utils/app_colors.dart';
import 'package:Readme/core/utils/text_style.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  bool loading = false;
  final supabase = Supabase.instance.client;

  void _showSnackBar(SnackBar snackBar) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }

  String? _validateForm() {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (username.isEmpty) {
      return 'Please enter a username';
    }
    if (email.isEmpty) {
      return 'Please enter your email address';
    }
    if (password.isEmpty) {
      return 'Please enter a password';
    }
    if (password.length < 6) {
      return 'Password must be at least 6 characters';
    }
    if (password != confirmPassword) {
      return 'Passwords do not match';
    }
    return null;
  }

  String _errorMessage(Object error) {
    final message = error.toString().toLowerCase();

    if (error is AuthException) {
      final authMessage = error.message.toLowerCase();
      if (authMessage.contains('failed host lookup') ||
          authMessage.contains('socketexception') ||
          authMessage.contains('network is unreachable')) {
        return 'No internet connection. Check your network and try again.';
      }
      return error.message;
    }

    if (message.contains('failed host lookup') ||
        message.contains('socketexception') ||
        message.contains('network is unreachable') ||
        message.contains('clientexception')) {
      return 'No internet connection. Check your network and try again.';
    }

    return 'Something went wrong. Please try again.';
  }

  Future<void> _syncProfileAfterSignUp({
    required String userId,
    required String username,
  }) async {
    try {
      await supabase.from('profiles').upsert({
        'id': userId,
        'name': username,
        'username': username,
      });
    } catch (e) {
      debugPrint('Profile sync after sign-up failed: $e');
    }
  }

  Future<void> createAccount() async {
    if (loading) return;

    final validationError = _validateForm();
    if (validationError != null) {
      _showSnackBar(
        SnackBar(
          content: Text(validationError),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      final reachable = await SupabaseConnectivity.canReachServer();
      if (!mounted) return;
      if (!reachable) {
        _showSnackBar(
          const SnackBar(
            content: Text(
              'Cannot reach Supabase. If you use an emulator, open Chrome there to '
              'test internet, then cold boot the emulator. On a phone, check Wi‑Fi.',
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 6),
          ),
        );
        return;
      }

      final username = _usernameController.text.trim();
      final email = _emailController.text.trim();

      final result = await supabase.auth.signUp(
        email: email,
        password: _passwordController.text,
        data: {
          'username': username,
          'name': username,
          'full_name': username,
        },
      );

      if (result.user != null) {
        await _syncProfileAfterSignUp(
          userId: result.user!.id,
          username: username,
        );
      }

      if (!mounted) return;

      if (result.session != null) {
        _showSnackBar(
          const SnackBar(
            content: Text('Account created successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        context.go('/home');
        return;
      }

      _showSnackBar(
        const SnackBar(
          content: Text(
            'Account created! Check your email to confirm, then log in.',
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );
      context.go('/signin');
    } on AuthException catch (e) {
      _showSnackBar(
        SnackBar(
          content: Text(_errorMessage(e)),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      _showSnackBar(
        SnackBar(
          content: Text(_errorMessage(e)),
          backgroundColor: Colors.red,
        ),
      );
      debugPrint(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
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
      textInputAction: TextInputAction.done,
    );
  }

  Widget _buildCreateAccountButton() {
    return GradientButton(
      loading: loading,
      text: "Create account",
      fontSize: 16,
      onTap: createAccount,
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
                context.go('/signin');
              },
              child: Text("Log in", style: textStyle_16RegularLinkBlue()),
            ),
          ],
        ),
      ],
    );
  }
}
