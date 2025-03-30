import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primaryColor = Color(0xFF4A90E2);
  static const Color secondaryColor = Color(0xFF00C853);
  static const Color accentColor = Color(0xFFFF9800);

  // Background Colors
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color cardBackgroundColor = Colors.white;

  // Text Colors
  static const Color primaryTextColor = Color(0xFF212121);
  static const Color secondaryTextColor = Color(0xFF757575);
  static const Color linkTextColor = Color(0xFF2196F3);

  // Status Colors
  static const Color errorColor = Color(0xFFE53935);
  static const Color warningColor = Color(0xFFFFB300);
  static const Color successColor = Color(0xFF43A047);

  // Risk Colors
  static const Color highRiskColor = Color(0xFFE53935);
  static const Color mediumRiskColor = Color(0xFFFFB300);
  static const Color lowRiskColor = Color(0xFF43A047);

  // Gradient Colors
  static final List<Color> primaryGradient = [
    const Color(0xFF4A90E2),
    const Color(0xFF63A4FF),
  ];

  static final List<Color> successGradient = [
    const Color(0xFF43A047),
    const Color(0xFF66BB6A),
  ];

  static final List<Color> warningGradient = [
    const Color(0xFFFFB300),
    const Color(0xFFFFD54F),
  ];

  static final List<Color> errorGradient = [
    const Color(0xFFE53935),
    const Color(0xFFEF5350),
  ];
}
