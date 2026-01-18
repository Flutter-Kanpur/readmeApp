import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:readme_blogapp/shared/widgets/bottom_navbar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;

  final pages = const [
    Center(child: Text("Home")),
    Center(child: Text("Search")),
    Center(child: Text("Create")),
    Center(child: Text("Trending")),
    Center(child: Text("Profile")),
  ];

  // ✅ ADD THIS
  @override
  void initState() {
    super.initState();
    _testSupabaseConnection();
  }

  // ✅ ADD THIS
  Future<void> _testSupabaseConnection() async {
    try {
      final supabase = Supabase.instance.client;
      final res = await supabase.from('blogs').select().limit(1);
      debugPrint('Supabase connected ✅ Response: $res');
    } catch (e) {
      debugPrint('Supabase connection error ❌: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: pages[currentIndex],
      bottomNavigationBar: Padding(
        padding: EdgeInsets.symmetric(horizontal: 18.sp, vertical: 18.sp),
        child: BottomNavbar(
          currentIndex: currentIndex,
          onTap: (index) => setState(() => currentIndex = index),
        ),
      ),
    );
  }
}
