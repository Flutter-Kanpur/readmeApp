import 'package:flutter/material.dart';

class CustomTextField extends StatefulWidget {
  final String text;

  final TextEditingController? controller;
  final bool isPassword;
  final bool enablePasswordToggle;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final int maxLines;
  final Color? hintColor;
  final double? hintFontSize;
  final FontWeight hintFontWeight;

  const CustomTextField({
    super.key,
    required this.text,
    this.controller,
    this.isPassword = false,
    this.enablePasswordToggle = true,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.maxLines = 1,
    this.hintColor,
    this.hintFontSize,
    this.hintFontWeight = FontWeight.w400,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late final TextEditingController _internalController;
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _internalController = widget.controller ?? TextEditingController();
    _obscureText = widget.isPassword;
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _internalController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      child: TextField(
        controller: _internalController,
        obscureText: widget.isPassword && _obscureText,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        maxLines: widget.isPassword ? 1 : widget.maxLines,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: widget.text,
          hintStyle: TextStyle(
            color: widget.hintColor ?? Colors.grey[600],
            fontSize: widget.hintFontSize ?? 14,
            fontWeight: widget.hintFontWeight,
          ),
          suffixIcon: widget.isPassword && widget.enablePasswordToggle
              ? IconButton(
                  icon: Icon(
                    _obscureText
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                )
              : null,
        ),
      ),
    );
  }
}
