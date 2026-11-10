import 'package:flutter/material.dart';

/// App color palette featuring Pepper Red as the primary brand color
/// alongside reader-optimized background and text colors.
class AppColors {
  AppColors._();

  // Primary Brand Colors (Pepper Red)
  static const Color pepperRed = Color(0xFFC41E3A); // Deep Pepper Red
  static const Color pepperRedDark = Color(0xFF9E142B); // Darker shade for accents/status
  static const Color pepperRedLight = Color(0xFFFF5252); // Energetic light red
  static const Color pepperRedSoft = Color(0xFFFFEBEE); // Subtle pastel red background

  // Neutral Colors
  static const Color background = Color(0xFFF9F9FB);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF1E1E24);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color divider = Color(0xFFE5E7EB);
  static const Color border = Color(0xFFD1D5DB);

  // Reader Themes
  // 1. Light Theme
  static const Color readerLightBg = Color(0xFFFFFFFF);
  static const Color readerLightText = Color(0xFF222222);

  // 2. Sepia Theme (Warm Paper)
  static const Color readerSepiaBg = Color(0xFFFBF0D9);
  static const Color readerSepiaText = Color(0xFF4A3E31);
  static const Color readerSepiaSecondary = Color(0xFF7D6B58);

  // 3. Night / Dark Theme
  static const Color readerDarkBg = Color(0xFF121214);
  static const Color readerDarkSurface = Color(0xFF1E1E24);
  static const Color readerDarkText = Color(0xFFE6E6E6);
  static const Color readerDarkSecondary = Color(0xFF9E9E9E);

  // Accent & Functional Colors
  static const Color gold = Color(0xFFF59E0B); // For bookmarks & stars
  static const Color success = Color(0xFF10B981);
  static const Color badgeBg = Color(0xFFF3F4F6);
  static const Color badgeText = Color(0xFF4B5563);
}

