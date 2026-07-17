import 'package:Readme/core/utils/app_colors.dart';
import 'package:Readme/core/utils/text_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../shared/widgets/gradient_background.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/textfield.dart';

/// Shown when the user opens a recovery link and lands in a recovery session.
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;
  bool _loading = false;
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showSnackBar(SnackBar snackBar) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }

  Future<void> _updatePassword() async {
    if (_loading) return;

    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (password.isEmpty) {
      _showSnackBar(
        const SnackBar(
          content: Text('Please enter a new password'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (password.length < 6) {
      _showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 6 characters'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (password != confirm) {
      _showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      await _supabase.auth.updateUser(
        UserAttributes(password: password),
      );

      if (!mounted) return;
      _showSnackBar(
        const SnackBar(
          content: Text('Password updated. You can log in now.'),
          backgroundColor: Colors.green,
        ),
      );
      await _supabase.auth.signOut();
      if (!mounted) return;
      context.go('/signin');
    } on AuthException catch (e) {
      _showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red,
        ),
      );
    } catch (_) {
      _showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => context.go('/signin'),
                  icon: Icon(
                    Icons.arrow_back,
                    color: AppColors.black,
                    size: 22.sp,
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(height: 80.h),
                      Text(
                        'Set a new password',
                        style: textStyle_24BoldBlack(),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        'Choose a strong password you haven\'t\nused before.',
                        textAlign: TextAlign.center,
                        style: textStyle_16RegularGrey(),
                      ),
                      SizedBox(height: 32.h),
                      CustomTextField(
                        text: 'New Password',
                        controller: _passwordController,
                        isPassword: true,
                        enablePasswordToggle: true,
                        hintColor: AppColors.subtitles,
                        hintFontSize: 16,
                      ),
                      SizedBox(height: 16.h),
                      CustomTextField(
                        text: 'Confirm Password',
                        controller: _confirmPasswordController,
                        isPassword: true,
                        enablePasswordToggle: true,
                        hintColor: AppColors.subtitles,
                        hintFontSize: 16,
                        textInputAction: TextInputAction.done,
                      ),
                      SizedBox(height: 24.h),
                      PrimaryButton(
                        loading: _loading,
                        text: 'Update password',
                        onPressed: _updatePassword,
                      ),
                      SizedBox(height: 40.h),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
