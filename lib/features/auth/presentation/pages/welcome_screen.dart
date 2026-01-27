import 'package:Readme/features/home_page/presentation/pages/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:Readme/core/utils/assets_path.dart';
import 'package:Readme/core/utils/text_style.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/gradient_background.dart';
import '../../../../shared/widgets/gradient_button.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in/src/token_types.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
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

      final GoogleSignIn signIn = GoogleSignIn.instance;

      try {
        await signIn.initialize(
          serverClientId: dotenv.env['WEB_CLIENT_ID'],
          clientId: dotenv.env['ANDROID_CLIENT_ID'],
        );
      } catch (e) {
        if (!mounted) return;
        _showSnackBar(
          context,
          SnackBar(
            content: Text('Configuration Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final GoogleSignInAccount? account = await signIn.authenticate();

      if (account == null) {
        if (!mounted) return;
        _showSnackBar(
          context,
          const SnackBar(
            content: Text('Login cancelled'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await account.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        if (!mounted) return;
        _showSnackBar(
          context,
          const SnackBar(
            content: Text('Unable to login. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final AuthResponse result = await Supabase.instance.client.auth
          .signInWithIdToken(provider: OAuthProvider.google, idToken: idToken);

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
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (context) => false,
        );
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
          content: Text('Unexpected Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      _setGoogleLoading(false);
    }
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
            Text("Let's you in", style: textStyle_24BoldBlack()),
            SizedBox(height: 12.h),
            Text(
              "Be part of a community that learns\nand builds together.",
              textAlign: TextAlign.center,
              style: textStyle_16RegularGrey(),
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
            GradientButton(
              text: "Create Account",
              onTap: () {
                context.go('/signup');
              },
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
              SvgPicture.asset(svgPath, height: 20.h, width: 20.w),
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
