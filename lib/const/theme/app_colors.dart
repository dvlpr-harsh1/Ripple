import 'package:flutter/material.dart';

class AppColors {
  // Gradient stops
  static const gradientPurple = Color(0xFF833AB4);
  static const gradientPink   = Color(0xFFE1306C);
  static const gradientOrange = Color(0xFFF77737);

  static const igGradient = LinearGradient(
    colors: [gradientPurple, gradientPink, gradientOrange],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Surfaces
  static const black      = Color(0xFF000000);
  static const surface    = Color(0xFF0E0E0E);
  static const card       = Color(0xFF161616);
  static const inputFill  = Color(0xFF1A1A1A);

  // Text
  static const textPrimary   = Colors.white;
  static const textSecondary = Colors.white70;
  static const textHint      = Colors.white38;

  // Semantic
  static const online  = Color(0xFF69F0AE);
  static const error   = Color(0xFFEF5350);
  static const blocked = Color(0xFF78909C);

  //Background
  static const transparentBackground = Colors.transparent;
}