import 'package:Readme/shared/widgets/app_bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainActionScreen extends StatefulWidget {
  final Widget child;
  const MainActionScreen({super.key, required this.child});

  @override
  State<MainActionScreen> createState() => _MainActionScreenState();
}

class _MainActionScreenState extends State<MainActionScreen> {
  int _getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/trending')) return 1;
    if (location.startsWith('/search')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/trending');
        break;
      case 2:
        context.go('/search');
        break;
      case 3:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: widget.child,
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _getCurrentIndex(context),
        onTap: (index) => _onItemTapped(index, context),
      ),
    );
  }
}
