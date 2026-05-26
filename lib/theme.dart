import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors (HSL-derived tailormade premium palette)
  static const Color obsidianBlack = Color(0xFF090A0F);
  static const Color deepSpaceBlue = Color(0xFF0F111E);
  static const Color glassCardBg = Color(0x12FFFFFF);
  static const Color glassCardBorder = Color(0x1F14B8A6); // Soft glowing teal
  
  static const Color primaryViolet = Color(0xFF8B5CF6); // Cyber Violet
  static const Color accentTeal = Color(0xFF14B8A6); // Hyper Teal
  static const Color neuralGrey = Color(0xFF94A3B8);
  static const Color softCrimson = Color(0xFFEF4444);
  
  // Custom Glassmorphic Decoration helper
  static BoxDecoration glassDecoration({
    Color? borderColor,
    Color? bgColor,
    double borderRadius = 16.0,
  }) {
    return BoxDecoration(
      color: bgColor ?? glassCardBg,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor ?? glassCardBorder,
        width: 1.0,
      ),
      boxShadow: [
        BoxShadow(
          color: (borderColor ?? glassCardBorder).withOpacity(0.05),
          blurRadius: 10,
          spreadRadius: 1,
        ),
      ],
    );
  }

  // Dark Theme configuration
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryViolet,
      scaffoldBackgroundColor: obsidianBlack,
      cardColor: deepSpaceBlue,
      colorScheme: const ColorScheme.dark(
        primary: primaryViolet,
        secondary: accentTeal,
        surface: deepSpaceBlue,
        error: softCrimson,
      ),
      
      // Text styling
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.outfit(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: -0.5,
        ),
        titleMedium: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        bodyLarge: GoogleFonts.outfit(
          fontSize: 16,
          color: Colors.white.withOpacity(0.9),
        ),
        bodyMedium: GoogleFonts.outfit(
          fontSize: 14,
          color: neuralGrey,
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: glassCardBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: glassCardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: glassCardBorder.withOpacity(0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accentTeal, width: 1.5),
        ),
        labelStyle: GoogleFonts.outfit(color: neuralGrey),
        hintStyle: GoogleFonts.outfit(color: neuralGrey.withOpacity(0.5)),
      ),

      // Slider styling
      sliderTheme: const SliderThemeData(
        activeTrackColor: accentTeal,
        inactiveTrackColor: Color(0x33FFFFFF),
        thumbColor: accentTeal,
        overlayColor: Color(0x1F14B8A6),
        valueIndicatorColor: deepSpaceBlue,
      ),
    );
  }
}
