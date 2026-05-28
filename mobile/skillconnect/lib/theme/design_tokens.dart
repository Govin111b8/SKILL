/// SkillConnect Design Tokens — standardized spacing, radius, elevation, typography.
library;

import 'package:flutter/material.dart';

/// Spacing scale (multiples of 4)
class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 48;
}

/// Border radius tokens
class AppRadius {
  AppRadius._();
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double pill = 100;
}

/// Elevation / shadow presets
class AppShadows {
  AppShadows._();
  static List<BoxShadow> sm(Color color) => [BoxShadow(color: color.withAlpha(20), blurRadius: 8, offset: const Offset(0, 2))];
  static List<BoxShadow> md(Color color) => [BoxShadow(color: color.withAlpha(40), blurRadius: 16, offset: const Offset(0, 6))];
  static List<BoxShadow> lg(Color color) => [BoxShadow(color: color.withAlpha(60), blurRadius: 24, offset: const Offset(0, 10))];
  static List<BoxShadow> xl(Color color) => [BoxShadow(color: color.withAlpha(80), blurRadius: 32, offset: const Offset(0, 14))];
}

/// Semantic colors
class AppColors {
  AppColors._();
  // Brand
  static const Color primary = Color(0xFF6366F1);
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF4F46E5);
  static const Color secondary = Color(0xFF06B6D4);
  static const Color accent = Color(0xFF8B5CF6);

  // Semantic
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);

  // Surfaces
  static const Color surfaceLight = Color(0xFFF8FAFC);
  static const Color surfaceDark = Color(0xFF0F172A);
  static const Color cardLight = Colors.white;
  static const Color cardDark = Color(0xFF1E293B);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderDark = Color(0xFF334155);

  // Gradients
  static const List<Color> primaryGradient = [Color(0xFF6366F1), Color(0xFF8B5CF6)];
  static const List<Color> heroGradient = [Color(0xFF4F46E5), Color(0xFF7C3AED), Color(0xFF0891B2)];
  static const List<Color> successGradient = [Color(0xFF10B981), Color(0xFF059669)];
  static const List<Color> warmGradient = [Color(0xFFF59E0B), Color(0xFFEF4444)];
}

/// Animation durations
class AppDurations {
  AppDurations._();
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration pageTransition = Duration(milliseconds: 350);
}

/// Icon sizes
class AppIconSizes {
  AppIconSizes._();
  static const double sm = 16;
  static const double md = 20;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}
