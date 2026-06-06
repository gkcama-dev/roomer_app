import 'package:flutter/material.dart';
import 'package:roomer/constants/app_colors.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData? prefixIcon; // Made optional for centered code input
  final bool obscureText;
  final TextInputType keyboardType;
  final TextAlign textAlign; // Added for centered group code input
  final double? letterSpacing; // Added for spacing out group code digits
  final TextStyle? hintStyle; // Added to support custom hint tracking

  const CustomTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.prefixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textAlign = TextAlign.start,
    this.letterSpacing,
    this.hintStyle,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textAlign: textAlign,
      style: TextStyle(color: AppColors.textDark, letterSpacing: letterSpacing, fontSize: textAlign == TextAlign.center ? 22 : 14, fontWeight: textAlign == TextAlign.center ? FontWeight.bold : FontWeight.normal),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: hintStyle ?? const TextStyle(color: AppColors.textGrey, fontSize: 14, letterSpacing: 0),
        filled: true,
        fillColor: AppColors.scaffoldBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: AppColors.textGrey) : null,
      ),
    );
  }
}