import 'package:flutter/material.dart';

class AppTheme {
  // Mibu Minimalist Monochromatic Theme
  static const Color black = Color(0xFF111111);
  static const Color pureBlack = Color(0xFF000000);
  static const Color seaBlue = Color(0xFF0284C7);
  static const Color white = Color(0xFFFFFFFF);
  static const Color grayBg = Color(0xFFF7F7F8);
  static const Color grayBorder = Color(0xFFE4E4E7);
  static const Color grayKeypad = Color(0xFFF2F2F4);
  static const Color grayTextMuted = Color(0xFF8E8E93);
  static const Color grayTextLight = Color(0xFFA1A1AA);

  // Status & Accents
  static const Color primary = Color(0xFF111111);
  static const Color primaryLight = Color(0xFF71717A);
  static const Color secondary = Color(0xFF27272A);
  static const Color expense = Color(0xFF111111);
  static const Color income = Color(0xFF111111);

  // Surface tokens
  static const Color darkBackground = Color(0xFF0C0C0E);
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color darkSurface = Color(0xFF18181B);
  static const Color darkSurfaceCard = Color(0xFF18181B);
  static const Color darkBorder = Color(0xFF27272A);
  static const Color lightBorder = Color(0xFFE4E4E7);
  static const Color darkTextPrimary = Colors.white;
  static const Color darkTextSecondary = Color(0xFF8E8E93);
  static const Color lightTextPrimary = Color(0xFF111111);
  static const Color lightTextSecondary = Color(0xFF71717A);

  // Minimal Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF111111), Color(0xFF27272A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient receiptScannerGradient = LinearGradient(
    colors: [Color(0xFF111111), Color(0xFF3F3F46)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: white,
      primaryColor: black,
      colorScheme: const ColorScheme.light(
        primary: black,
        secondary: black,
        surface: white,
        error: Colors.black,
      ),
      cardTheme: CardThemeData(
        color: white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: grayBorder, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: black,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: black),
      ),
      fontFamily: 'Inter',
      useMaterial3: true,
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      primaryColor: white,
      colorScheme: const ColorScheme.dark(
        primary: white,
        secondary: white,
        surface: darkSurface,
        error: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: darkSurfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: darkBorder, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackground,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: white),
      ),
      fontFamily: 'Inter',
      useMaterial3: true,
    );
  }
}
