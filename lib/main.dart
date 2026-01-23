import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:readme_blogapp/features/home_page/home_screen.dart';
import 'package:readme_blogapp/features/profile_page/presentation/screens/edit_profile_screen.dart';
import 'package:readme_blogapp/features/profile_page/presentation/screens/profile_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: 'https://uktnmjykbyuvfsbtawwg.supabase.co', anonKey: 'sb_publishable_p3fuhjG-r3Iu2AA0Ayak2w_9Ms57rb5');
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
          home: ProfileScreen(),
        );
      },
    );
  }
}
