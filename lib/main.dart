import 'package:Readme/core/network/supabase_connectivity.dart';
import 'package:Readme/core/router/routes.dart';
import 'package:Readme/core/secrets/app_secrets.dart';
import 'package:Readme/core/updater/app_upgrader.dart';
import 'package:Readme/core/utils/assets_path.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:Readme/core/network/readme_supabase.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AssetsPath.init();
  await dotenv.load(fileName: '.env');

  final envIssue = EnvValidator.validate();
  if (envIssue != null) {
    runApp(ConfigErrorApp(message: envIssue.message));
    return;
  }

  await Supabase.initialize(
    url: AppSecrets.supabaseUrl,
    anonKey: AppSecrets.supabaseAnonKey,
  );
  runApp(const MyApp());
}

class ConfigErrorApp extends StatelessWidget {
  const ConfigErrorApp({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Configuration error',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(message),
                const SizedBox(height: 16),
                const Text(
                  'Copy .env.example to .env, fill in your keys, then run '
                  './tool/enable_standalone_env.sh and flutter clean && flutter run.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    ReadmeSupabase.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        AppRouter.router.go('/reset-password');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      builder: (context, child) {
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'ReadMe',
          theme: ThemeData(
            textTheme: GoogleFonts.poppinsTextTheme(),
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
          ),
          localizationsDelegates: [
            FlutterQuillLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
          ],
          routerConfig: AppRouter.router,
          builder: (context, child) {
            return AppUpgrader(
              child: child ?? const SizedBox.shrink(),
            );
          },
        );
      },
    );
  }
}
