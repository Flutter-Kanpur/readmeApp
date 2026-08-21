import 'package:Readme/core/utils/app_colors.dart';
import 'package:Readme/core/utils/text_style.dart';
import 'package:Readme/features/auth/presentation/state/auth_controller_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../shared/widgets/gradient_background.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/textfield.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail});

  final String? initialEmail;

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  late final TextEditingController _emailController;
  bool _emailSent = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _showSnackBar(SnackBar snackBar) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }

  String _errorMessage(Object error) {
    if (error is AuthException) {
      final authMessage = error.message.toLowerCase();
      if (authMessage.contains('failed host lookup') ||
          authMessage.contains('socketexception') ||
          authMessage.contains('network is unreachable')) {
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

    return 'Something went wrong. Please try again.';
  }

  Future<void> _sendResetLink() async {
    if (ref.read(authControllerProvider).isLoading) return;

    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showSnackBar(
        const SnackBar(
          content: Text('Please enter your email address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!email.contains('@')) {
      _showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final reachable = await ref
          .read(authControllerProvider.notifier)
          .sendPasswordReset(email);
      if (!mounted) return;
      if (!reachable) {
        _showSnackBar(
          const SnackBar(
            content: Text(
              'Cannot reach Supabase. Check your internet connection and try again.',
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
        return;
      }

      setState(() => _emailSent = true);
      _showSnackBar(
        const SnackBar(
          content: Text(
            'Reset link sent. Open it on this phone — it will bring you back into the app to set a new password.',
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );
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
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/signin');
                    }
                  },
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
                        'Forgot password?',
                        style: textStyle_24BoldBlack(),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        _emailSent
                            ? 'We sent a reset link to your email.\nOpen it to choose a new password, then\ncome back here to log in.'
                            : 'Enter the email linked to your account\nand we\'ll send you a reset link.',
                        textAlign: TextAlign.center,
                        style: textStyle_16RegularGrey(),
                      ),
                      SizedBox(height: 32.h),
                      CustomTextField(
                        text: 'Email Address',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        isPassword: false,
                        hintColor: AppColors.subtitles,
                        hintFontSize: 16,
                        textInputAction: TextInputAction.done,
                      ),
                      SizedBox(height: 24.h),
                      PrimaryButton(
                        loading: ref.watch(authControllerProvider).isLoading,
                        text: _emailSent ? 'Resend link' : 'Send reset link',
                        onPressed: _sendResetLink,
                      ),
                      SizedBox(height: 20.h),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/signin');
                          }
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.h),
                          child: Text(
                            'Back to Log in',
                            style: textStyle_16RegularLinkBlue(),
                          ),
                        ),
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
