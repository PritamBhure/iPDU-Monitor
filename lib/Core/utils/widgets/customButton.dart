import 'package:flutter/material.dart';
import '../../constant/appColors_constant.dart';
import '../../constant/appTextWidget.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isOutlined; // Toggle between Filled (false) and Outlined (true)
  final Color? color;    // Custom background or border color
  final Color? textColor;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isOutlined = false, // Defaults to "Apply" style
    this.color,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Common Dimensions
    const padding = EdgeInsets.symmetric(vertical: 16);
    final borderRadius = BorderRadius.circular(8);

    // 2. Render Outlined Button (Cancel Style)
    if (isOutlined) {
      return OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: padding,
          side: BorderSide(color: color ?? Colors.grey), // Default grey border
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
        ),
        onPressed: onPressed,
        child: AppText(
          text,
          size: TextSize.body,
          color: textColor ?? Colors.grey, // Default grey text
          fontWeight: FontWeight.bold,
        ),
      );
    }

    // 3. Render Elevated Button (Apply/Login Style)
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? AppColors.primaryBlue, // Default Blue
        padding: padding,
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
        elevation: 2,
      ),
      onPressed: onPressed,
      child: AppText(
        text,
        size: TextSize.body,
        color: textColor ?? Colors.white, // Default white text
        fontWeight: FontWeight.bold,
      ),
    );
  }
}