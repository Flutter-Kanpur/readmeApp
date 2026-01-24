import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// A reusable gradient button widget with glossy highlight effects.
///
/// Designed to provide a premium-looking button UI with:
/// - Gradient background
/// - Soft light reflections
/// - Responsive width support using ScreenUtil
/// - Customizable text, size, and font
///
/// Suitable for authentication buttons, CTAs, and modern UI designs.
class GradientButton extends StatelessWidget {
  /// The label text displayed on the button
  final String text;

  /// Callback executed when the button is tapped
  final VoidCallback onTap;

  /// Height of the button (default: 45)
  /// Controls overall size and border radius
  final double height;

  /// Width of the button (default: full width)
  /// Can be constrained externally if needed
  final double width;

  /// Optional custom font size for button text
  final double? fontSize;

  const GradientButton({
    super.key,
    required this.text,
    required this.onTap,
    this.height = 45, // Default button height
    this.width = double.infinity,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      /// Handles tap interaction for the button
      onTap: onTap,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          /// Prevents the button from becoming too wide on large screens
          /// Uses ScreenUtil to maintain responsiveness
          maxWidth: 400.w,
        ),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            /// Creates pill-shaped rounded button
            borderRadius: BorderRadius.circular(height / 2),

            /// Shadow for elevation and depth effect
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              /// Base dark gradient background layer
              /// Provides the primary button color tone
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(height / 2),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment(0, 9),
                    stops: [0.0, 0.05],
                    colors: [Color.fromARGB(255, 25, 25, 25), Colors.black],
                  ),
                ),
              ),

              /// Top-left glossy highlight layer
              /// Adds premium reflective lighting effect
              Container(
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(height / 2),
                  gradient: LinearGradient(
                    begin: Alignment(-1, -1),
                    end: Alignment(0, 1),
                    stops: [-1, 0.2],
                    colors: [
                      Colors.white.withValues(alpha: 0.95),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),

              /// Top-center soft glow highlight
              /// Enhances depth and shine in the middle area
              Container(
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(height / 2),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.center,
                    colors: [
                      Colors.white.withValues(alpha: 0.28),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),

              /// Top-right reflective highlight
              /// Balances lighting across the button surface
              Container(
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(height / 2),
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomCenter,
                    stops: [-1, 0.2],
                    colors: [
                      Colors.white.withValues(alpha: 0.55),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),

              /// Centered button label text
              /// Automatically scales based on button height if fontSize is not provided
              Center(
                child: Text(
                  text,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: fontSize ?? height * 0.25,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
