import 'dart:io' show Platform;

import 'package:Readme/core/utils/assets_path.dart';
import 'package:Readme/core/utils/text_style.dart';
import 'package:Readme/features/auth/presentation/state/auth_controller_provider.dart';
import 'package:Readme/shared/widgets/primary_button.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/widgets/gradient_background.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  bool _isGoogleLoading = false;

  Future<void> continueWithGoogle(BuildContext context) async {
    if (_isGoogleLoading) return;

    _setGoogleLoading(true);

    try {
      _showSnackBar(
        context,
        const SnackBar(
          content: Text('Signing in with Google...'),
          duration: Duration(seconds: 2),
        ),
      );

      final webClientId = dotenv.env['WEB_CLIENT_ID']?.trim();
      if (webClientId == null || webClientId.isEmpty) {
        if (!mounted) return;
        _showSnackBar(
          context,
          const SnackBar(
            content: Text(
              'Google Sign-In is not configured (missing WEB_CLIENT_ID).',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final GoogleSignIn signIn = GoogleSignIn.instance;

      try {
        // Android resolves the native OAuth client from package name + SHA-1.
        // Pass only the Web client as serverClientId so Supabase gets an ID token.
        // iOS needs its iOS client ID via clientId when configured.
        await signIn.initialize(
          serverClientId: webClientId,
          clientId: (!kIsWeb && Platform.isIOS)
              ? dotenv.env['IOS_CLIENT_ID']?.trim()
              : null,
        );
      } catch (e) {
        if (!mounted) return;
        _showSnackBar(
          context,
          SnackBar(
            content: Text(_googleErrorMessage(e)),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final GoogleSignInAccount account = await signIn.authenticate();

      final GoogleSignInAuthentication googleAuth = account.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        if (!mounted) return;
        _showSnackBar(
          context,
          const SnackBar(
            content: Text(
              'Google did not return an ID token. Check that WEB_CLIENT_ID '
              'is your OAuth Web client and matches Supabase Google settings.',
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
        return;
      }

      final AuthResponse result = await ref
          .read(authControllerProvider.notifier)
          .signInWithGoogleIdToken(idToken);

      if (result.user != null && result.session != null) {
        if (!mounted) return;
        _showSnackBar(
          context,
          const SnackBar(
            content: Text('Login successful!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        if (!mounted) return;
        // Replace the auth stack so Welcome is not left under Home/Blog.
        context.go('/home');
      } else {
        if (!mounted) return;
        _showSnackBar(
          context,
          const SnackBar(
            content: Text('Unable to login. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } on GoogleSignInException catch (e) {
      if (!mounted) return;
      if (e.code == GoogleSignInExceptionCode.canceled) {
        _showSnackBar(
          context,
          const SnackBar(
            content: Text('Google sign-in cancelled'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
      _showSnackBar(
        context,
        SnackBar(
          content: Text(_googleErrorMessage(e)),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      _showSnackBar(
        context,
        SnackBar(
          content: Text('Authentication Error: ${e.message}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(
        context,
        SnackBar(
          content: Text(_googleErrorMessage(e)),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      _setGoogleLoading(false);
    }
  }

  String _googleErrorMessage(Object error) {
    final text = error.toString().toLowerCase();
    if (text.contains('reauth failed') ||
        text.contains('code: 10') ||
        text.contains('[10]') ||
        text.contains('code: 16') ||
        text.contains('[16]')) {
      return 'Google Sign-In failed. Add this app\'s SHA-1 in Google Cloud '
          'for package com.drishtant.readme, then retry.';
    }
    if (text.contains('canceled') || text.contains('cancelled')) {
      return 'Google sign-in cancelled';
    }
    return 'Unable to sign in with Google. Please try again.';
  }

  void _setGoogleLoading(bool value) {
    if (!mounted) return;
    setState(() {
      _isGoogleLoading = value;
    });
  }

  void _showSnackBar(BuildContext context, SnackBar snackBar) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          children: [
            Spacer(flex: 15),
            Image.asset(
              AssetsPath.brandImage,
              package: AssetsPath.package,
              height: 100.h,
            ),
            SizedBox(height: 12.h),
            Text("Let's you in", style: textStyle_24BoldBlack()),
            SizedBox(height: 12.h),
            Text(
              "Be part of a space where community \nlearns and share together.",
              textAlign: TextAlign.center,
              style: textStyle_16RegularGrey().copyWith(height: 1.25),
            ),
            Spacer(flex: 1),

            // Google Button
            _buildSocialButton(
              onTap: () {
                continueWithGoogle(context);
              },
              label: "Continue with Google",
              svgPath: AssetsPath.googleIcon,
              isLoading: _isGoogleLoading,
            ),

            SizedBox(height: 12.h),
            // Email Button
            _buildSocialButton(
              onTap: () {
                context.go('/signin');
              },
              label: "Sign in with Email",
              svgPath: AssetsPath.phoneIcon,
            ),

            20.verticalSpace,

            Row(
              children: [
                Expanded(child: Divider(color: Colors.grey.withOpacity(0.3))),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Text("OR", style: textStyle_14RegularBlack()),
                ),
                Expanded(child: Divider(color: Colors.grey.withOpacity(0.3))),
              ],
            ),

            20.verticalSpace,

            // Create Account Button - takes full width with internal max width constraint
            PrimaryButton(
              text: "Create Account",
              onPressed: () {
                context.go('/signup');
              },
            ),

            SizedBox(height: 16.h),
            TextButton(
              onPressed: () => context.push('/privacy-policy'),
              child: Text(
                'Privacy Policy',
                style: textStyle_14RegularBlack().copyWith(
                  fontSize: 13.sp,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.underline,
                ),
              ),
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
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
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
            if (isLoading) ...[
              SizedBox(
                height: 20.h,
                width: 20.h,
                child: const CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12.w),
            ] else ...[
              SvgPicture.asset(
                svgPath,
                package: AssetsPath.package,
                height: 20.h,
                width: 20.w,
              ),
              SizedBox(width: 12.w),
            ],
            Text(
              label,
              style: textStyle_16RegularBlack()
            ),
          ],
        ),
      ),
    );
  }
}
