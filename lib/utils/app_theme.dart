import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color background = Color(0xFF0F172A); // Deep Navy/Black
  static const Color surface = Color(0xFF1E293B); // Slightly lighter for cards
  static const Color primary = Color(0xFF6366F1); // Indigo
  static const Color income = Color(0xFF10B981); // Emerald Green
  static const Color expense = Color(0xFFEF4444); // Red/Pink
  static const Color textPrimary = Color(0xFFF8FAFC); // White-ish
  static const Color textSecondary = Color(0xFF94A3B8); // Grey

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: ColorScheme.dark(
        primary: primary,
        surface: surface,
        error: expense,
      ),
      textTheme: GoogleFonts.outfitTextTheme(
        ThemeData.dark().textTheme,
      ).apply(bodyColor: textPrimary, displayColor: textPrimary),
      cardTheme: CardThemeData(
        color: surface.withValues(alpha: 0.7),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
    );
  }
}
