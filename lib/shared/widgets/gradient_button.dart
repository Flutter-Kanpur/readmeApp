import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final double height;
  final double width;
  final double? fontSize;

  const GradientButton({
    super.key,
    required this.text,
    required this.onTap,
    this.height = 45, //default height
    this.width = double.infinity,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 400.w, // Internal max width limit
          //400.w is use acc to screen size
        ),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(height / 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              /// Base dark gradient
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

              //top left corner ka gradient
              Container(
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(height / 2),
                  gradient: LinearGradient(
                    begin: Alignment(-1, -1),
                    end: Alignment(0, 1),
                    stops: [-1, 0.2],
                    colors: [
                      Colors.white.withOpacity(0.95),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),

              //top center ka gradient
              Container(
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(height / 2),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.center,

                    colors: [
                      Colors.white.withOpacity(0.28),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),

              //top right corner ka gradient
              Container(
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(height / 2),
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomCenter,
                    stops: [-1, 0.2],

                    colors: [
                      Colors.white.withOpacity(0.55),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),

              /// Text
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
