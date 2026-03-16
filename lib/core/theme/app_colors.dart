import 'package:flutter/material.dart';

/// App color palette - Pinterest-inspired minimalist design
class AppColors {
  // Prevent instantiation
  AppColors._();

  // Background colors - Airy & Clean
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFF5F5F5);
  
  // Text colors
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textTertiary = Color(0xFF9E9E9E);
  
  // Accent colors
  static const Color primary = Color(0xFF2D2D2D);
  static const Color accent = Color(0xFFE91E63);
  
  // Semantic colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFFA726);
  
  // Border & Divider
  static const Color border = Color(0xFFE0E0E0);
  static const Color divider = Color(0xFFEEEEEE);
  
  // Shadow color for subtle elevation
  static Color shadow = Colors.black.withValues(alpha: 0.08);
}
