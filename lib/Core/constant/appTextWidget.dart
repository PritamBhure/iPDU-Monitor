import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// --- 1. SIZE CONSTANTS (Single Location Control) ---
class TextSize {
  static const double huge = 24.0;       // Gauge Values
  static const double large = 20.0;      // Offline Title / Big Stats
  static const double title = 16.0;      // AppBar Title, Section Headers
  static const double subtitle = 13.0;   // Detail Row Values, Outlet Names
  static const double body = 12.0;       // Table Rows, Sensor Values
  static const double tableHeader = 11.0;// Data Table Headers
  static const double small = 10.0;      // Labels, IP Address
  static const double micro = 9.0;       // Mini Labels inside Gauge
}

// --- 2. CUSTOM TEXT WIDGET ---
class AppText extends StatelessWidget {
  final String text;
  final double size; // Pass TextSize.title, TextSize.body, etc.
  final Color? color;
  final FontWeight? fontWeight;
  final TextAlign? textAlign;
  final TextOverflow? overflow;

  const AppText(
      this.text, {
        super.key,
        required this.size, // Force user to pick a standard size
        this.color,
        this.fontWeight,
        this.textAlign,
        this.overflow,
      });

  @override
  Widget build(BuildContext context) {
    // --- MEDIA QUERY LOGIC ---
    // Simple scaling: On wider screens (Tablets/Web), increase font slightly
    double screenWidth = MediaQuery.of(context).size.width;
    double scaleFactor = screenWidth > 600 ? 1.2 : 1.0;

    return Text(
      text,
      textAlign: textAlign,
      overflow: overflow,
      style: GoogleFonts.jetBrainsMono(
        fontSize: size * scaleFactor, // Auto-adjusts size
        color: color ?? Colors.white, // Default to white if null
        fontWeight: fontWeight ?? FontWeight.normal,
      ),
    );
  }
}