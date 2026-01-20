import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:readme_blogapp/features/auth/presentation/pages/login_with_email.dart';
import 'package:readme_blogapp/features/auth/presentation/pages/login_with_google.dart';
import 'package:readme_blogapp/features/auth/presentation/pages/signup_screen.dart';
import 'package:readme_blogapp/features/home_page/home_screen.dart';
import 'package:readme_blogapp/shared/widgets/gradient_background.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:readme_blogapp/shared/widgets/gradient_button.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://uktnmjykbyuvfsbtawwg.supabase.co',
    anonKey: 'sb_publishable_p3fuhjG-r3Iu2AA0Ayak2w_9Ms57rb5',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Flutter Demo',
          theme: ThemeData(
            textTheme: GoogleFonts.poppinsTextTheme(),
            colorScheme: .fromSeed(seedColor: Colors.deepPurple),
          ),
          home: const LoginWithEmail(),
        );
      },
    );
  }
}
