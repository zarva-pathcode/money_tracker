import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Primary colors extracted from previous UI implementation
  static const Color primaryBlue = Color(0xFF2196F3);
  static const Color scaffoldBg = Color(0xFFF8F9FA);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryBlue,
      primary: primaryBlue,
      onPrimary: Colors.white,
      surface: Colors.white,
      brightness: Brightness.light,
    ),

    scaffoldBackgroundColor: scaffoldBg,

    // GLOBAL FONT: LATO
    textTheme: GoogleFonts.latoTextTheme().copyWith(
      bodyLarge: GoogleFonts.lato(fontSize: 16, color: Colors.black87),
      bodyMedium: GoogleFonts.lato(fontSize: 14, color: Colors.black87),
      titleLarge: GoogleFonts.lato(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
      labelLarge: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.bold, color: primaryBlue),
    ),

    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
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
      backgroundColor: primaryBlue,
      foregroundColor: Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryBlue,
        side: const BorderSide(color: primaryBlue, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
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
        borderSide: const BorderSide(color: primaryBlue, width: 1.5),
      ),
      labelStyle: GoogleFonts.lato(color: Colors.grey[700]),
      hintStyle: GoogleFonts.lato(color: Colors.grey[400]),
    ),

    cardTheme: const CardThemeData(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
      margin: EdgeInsets.all(8),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryBlue,
      primary: primaryBlue,
      onPrimary: Colors.white,
      surface: const Color(0xFF1E1E1E),
      brightness: Brightness.dark,
      background: const Color(0xFF121212),
    ),

    scaffoldBackgroundColor: const Color(0xFF121212),

    textTheme: GoogleFonts.latoTextTheme(ThemeData.dark().textTheme).copyWith(
      bodyLarge: GoogleFonts.lato(fontSize: 16, color: Colors.white),
      bodyMedium: GoogleFonts.lato(fontSize: 14, color: Colors.white70),
      titleLarge: GoogleFonts.lato(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
      labelLarge: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.bold, color: primaryBlue),
    ),

    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFF1E1E1E),
      elevation: 0,
      scrolledUnderElevation: 1,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      titleTextStyle: GoogleFonts.lato(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
    ),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryBlue,
      foregroundColor: Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryBlue,
        side: const BorderSide(color: primaryBlue, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2C2C2C),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade800),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade800),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryBlue, width: 1.5),
      ),
      labelStyle: GoogleFonts.lato(color: Colors.white70),
      hintStyle: GoogleFonts.lato(color: Colors.white38),
    ),

    cardTheme: const CardThemeData(
      color: Color(0xFF1E1E1E),
      elevation: 2,
      shadowColor: Colors.black54,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
      margin: EdgeInsets.all(8),
    ),
  );
}
