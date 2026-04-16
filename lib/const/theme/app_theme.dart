import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static final themeDark = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.black,

    textTheme: GoogleFonts.interTextTheme(
      const TextTheme(
        // App Titles
        headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),

        // Chat Username
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),

        // Message Text
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),

        // Secondary text (last message preview)
        bodyMedium: TextStyle(fontSize: 14, color: Colors.white70),

        // Timestamp
        bodySmall: TextStyle(fontSize: 12, color: Colors.white54),

        // Labels (online, typing)
        labelLarge: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),

        // Small labels / badges
        labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
      ),
    ),

    // 🎯 INPUT FIELD
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.deepPurple),
      ),
      contentPadding: const EdgeInsets.all(12),
    ),

    // 🎯 BOTTOM NAV
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.transparent,
      selectedIconTheme: IconThemeData(color: Colors.deepPurple),
      unselectedIconTheme: IconThemeData(color: Colors.white60),
    ),
  );

  static final themeLight = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.white,
    textTheme: GoogleFonts.interTextTheme(),
  );
}