import 'package:flutter/material.dart';
import 'package:readme_blogapp/shared/widgets/bottom_navbar.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: pages[currentIndex],
        bottomNavigationBar: BottomNavbar(currentIndex: currentIndex,onTap: (index) => setState(() => currentIndex = index),
      ),
      );
  }
}
