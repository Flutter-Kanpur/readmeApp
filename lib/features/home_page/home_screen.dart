import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:readme_blogapp/shared/widgets/bottom_navbar.dart';
import 'package:readme_blogapp/shared/widgets/gradient_background.dart';
import 'package:readme_blogapp/shared/widgets/textfield.dart';
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
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      bottomNavigationBar: Padding(
        padding: EdgeInsets.symmetric(horizontal: 18.sp, vertical: 18.sp),
        child: BottomNavbar(
          currentIndex: currentIndex,
          onTap: (index) => setState(() => currentIndex = index),
        ),
      ),
      body:GradientBackground(child: CustomTextField(text: "Username",),));
  }
}
