import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryDark = Color(0xFF4B44CC);
  static const Color primaryLight = Color(0xFFEEEDFF);

  static const Color income = Color(0xFF22C55E);
  static const Color expense = Color(0xFFEF4444);
  static const Color neutral = Color(0xFF64748B);

  static const Color background = Color(0xFFF8F9FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9);

  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textHint = Color(0xFFCBD5E1);

  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFF1F5F9);

  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF22C55E);

  // Category colors
  static const Map<String, Color> categoryColors = {
    'FOOD': Color(0xFFFF6B6B),
    'TRANSPORT': Color(0xFF4ECDC4),
    'HOUSING': Color(0xFF45B7D1),
    'HEALTHCARE': Color(0xFF96CEB4),
    'ENTERTAINMENT': Color(0xFFFFEAA7),
    'SHOPPING': Color(0xFFDDA0DD),
    'UTILITIES': Color(0xFF98D8C8),
    'EDUCATION': Color(0xFFAED6F1),
    'PERSONAL': Color(0xFFF8C8D4),
    'SALARY': Color(0xFF22C55E),
    'FREELANCE': Color(0xFF10B981),
    'INVESTMENT': Color(0xFF059669),
    'GIFT': Color(0xFF34D399),
    'OTHER': Color(0xFF94A3B8),
  };

  static Color categoryColor(String category) =>
      categoryColors[category] ?? neutral;
}
