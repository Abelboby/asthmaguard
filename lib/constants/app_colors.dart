import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primaryColor = Color(0xFF00ADB5); // Teal blue
  static const Color secondaryColor = Color(0xFF393E46); // Dark gray

  static const Color accentColor = Color(0xFF00ADB5); // Teal blue accent

  // Background Colors
  static const Color backgroundColor =
      Color(0xFFEEEEEE); // Light gray background
  static const Color cardBackgroundColor = Colors.white;

  // Text Colors
  static const Color primaryTextColor =
      Color(0xFF222831); // Very dark gray for text
  static const Color secondaryTextColor =
      Color(0xFF393E46); // Dark gray for secondary text
  static const Color linkTextColor = Color(0xFF00ADB5); // Teal blue for links

  // Status Colors
  static const Color errorColor =
      Color(0xFFE53935); // Keep for good error visibility
  static const Color warningColor = Color(0xFFFFB300); // Keep amber for warning
  static const Color successColor = Color(0xFF00ADB5); // Teal blue for success

  // Risk Colors
  static const Color highRiskColor =
      Color(0xFFE53935); // Keep red for high risk
  static const Color mediumRiskColor =
      Color(0xFFFFB300); // Keep amber for medium risk
  static const Color lowRiskColor = Color(0xFF00ADB5); // Teal blue for low risk

  // Gradient Colors
  static final List<Color> primaryGradient = [
    const Color(0xFF00ADB5), // Teal blue
    const Color(0xFF00ADB5).withOpacity(0.8), // Teal blue with opacity
  ];

  static final List<Color> successGradient = [
    const Color(0xFF00ADB5), // Teal blue
    const Color(0xFF00ADB5).withOpacity(0.7), // Teal blue with opacity
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
