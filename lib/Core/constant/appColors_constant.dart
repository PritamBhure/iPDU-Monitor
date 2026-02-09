import 'package:flutter/material.dart';

class AppColors {
  // Backgrounds
  static const Color backgroundDeep = Color(0xFF0D1117);
  static const Color cardSurface = Color(0xFF161B22);
  static const Color panelBorder = Color(0xFF30363D);

  // Accents
  static const Color primaryBlue = Color(0xFF2F81F7);
  static const Color logoBG = Color(0xFF103A75);

  static const Color accentOrange = Color(0xFFD29922);
  static const Color accentGreen = Color(0xFF2EA043);
  static const Color accentRed = Color(0xFFDA3633);

  // Text
  static const Color textPrimary = Color(0xFFC9D1D9);
  static const Color textSecondary = Color(0xFF8B949E);
  static const Color textHighlighter = Colors.white;

  // Status Backgrounds
  static Color statusGreenBg = accentGreen.withOpacity(0.15);
  static Color statusRedBg = accentRed.withOpacity(0.15);
  static Color statusBlueBg = primaryBlue.withOpacity(0.15);
}