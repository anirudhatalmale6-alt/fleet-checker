import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryDark = Color(0xFF0D1B2A);
  static const Color primary = Color(0xFF1B2D45);
  static const Color accent = Color(0xFF2196F3);
  static const Color accentLight = Color(0xFF64B5F6);
  static const Color success = Color(0xFF4CAF50);
  static const Color danger = Color(0xFFE53935);
  static const Color warning = Color(0xFFFF9800);
  static const Color surface = Color(0xFF1E3A5F);
  static const Color cardBg = Color(0xFF243B55);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB0BEC5);

  static ThemeData get theme => ThemeData(
        brightness: Brightness.dark,
        primaryColor: primary,
        scaffoldBackgroundColor: primaryDark,
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        colorScheme: const ColorScheme.dark(
          primary: accent,
          secondary: accentLight,
          surface: surface,
          error: danger,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: primary,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        cardTheme: CardThemeData(
          color: cardBg,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: textSecondary.withValues(alpha: 0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: accent, width: 2),
          ),
          labelStyle: const TextStyle(color: textSecondary),
          hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.5)),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: accent,
          foregroundColor: Colors.white,
        ),
      );
}
