import 'package:flutter/material.dart';

class AppColors {
  static const Color neonCyan = Color(0xFF00F0FF);
  static const Color neonGreen = Color(0xFF39FF14); // Radioactive Green
  static const Color neonYellow = Color(0xFFFFEA00); // Neon Yellow
  static const Color neonBlue = Color(0xFF007BFF);
  static const Color neonPurple = Color(0xFFD500F9);
  static const Color backgroundColor = Color(0xFF0F1221);
  static const Color textPrimary = Colors.white;
  static const Color textMuted = Colors.grey;
  static const Color surface = Color(0xFF1E1E2E); // Dark tile color
  static const Color surfaceLight = Color(0xFF2A2A3A); // Slightly lighter
  static const Color border = Colors.white24;

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Colors.black, Color(0xFF0F1221)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
