import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // New Color Palette
  static const Color white = Color(0xFFFFFFFF);
  static const Color primaryNavy = Color(0xFF10375C);
  static const Color accentOrange = Color(0xFFEB8317);
  static const Color brightYellow = Color(0xFFF3C623);
  static const Color scaffoldBg = Color(0xFFF4F6FF);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryNavy,
      primary: primaryNavy,
      secondary: accentOrange,
      tertiary: brightYellow,
      surface: white,
      background: scaffoldBg,
      onPrimary: white,
      onSecondary: white,
      brightness: Brightness.light,
    ),

    scaffoldBackgroundColor: scaffoldBg,

    // GLOBAL FONT: LATO
    textTheme: GoogleFonts.latoTextTheme().copyWith(
      bodyLarge: GoogleFonts.lato(fontSize: 16, color: Colors.black87),
      bodyMedium: GoogleFonts.lato(fontSize: 14, color: Colors.black87),
      titleLarge: GoogleFonts.lato(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
      labelLarge: GoogleFonts.lato(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: primaryNavy,
      ),
    ),

    appBarTheme: AppBarTheme(
      backgroundColor: white,
      elevation: 0,
      scrolledUnderElevation: 1,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      titleTextStyle: GoogleFonts.lato(
        color: Colors.black87,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: const IconThemeData(color: Colors.black87),
    ),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryNavy,
      foregroundColor: white,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryNavy,
        foregroundColor: white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryNavy,
        side: const BorderSide(color: primaryNavy, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryNavy, width: 1.5),
      ),
      labelStyle: GoogleFonts.lato(color: Colors.grey[700]),
      hintStyle: GoogleFonts.lato(color: Colors.grey[400]),
    ),

    cardTheme: const CardThemeData(
      color: white,
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      margin: EdgeInsets.all(8),
    ),
  );
}
