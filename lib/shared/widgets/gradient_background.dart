import 'package:flutter/material.dart';

class GradientBackground extends StatelessWidget {
  const GradientBackground({super.key, this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF4373E2).withOpacity(0.48),
              const Color(0xFF4373E2).withOpacity(0.28),
              const Color(0xFF4373E2).withOpacity(0.15),
              Colors.white.withOpacity(0.15),
              Colors.white,
            ],
            stops: const [
              0.0,
              0.08,
              0.12,
              0.20,
              0.25,
            ],
          ),
        ),
        child: child,
      ),
    );
  }
}

