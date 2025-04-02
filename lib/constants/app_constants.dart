import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  // API Constants
  static String get weatherApiBaseUrl =>
      dotenv.env['WEATHER_API_BASE_URL'] ??
      'https://api.openweathermap.org/data/2.5';
  static String get weatherApiKey => dotenv.env['WEATHER_API_KEY'] ?? '';

  // Risk Status Constants
  static String get highRisk =>
      dotenv.env['HIGH_RISK'] ?? 'High risk - Consult a doctor immediately';
  static String get mediumRisk => dotenv.env['MEDIUM_RISK'] ?? 'Medium risk';
  static String get lowRisk => dotenv.env['LOW_RISK'] ?? 'Low risk';

  // ACT Score Thresholds - Updated to reflect standard interpretation
  // Lower scores indicate higher risk (poorer control)
  static double get lowRiskThreshold =>
      double.tryParse(dotenv.env['LOW_RISK_THRESHOLD'] ?? '') ??
      20.0; // ACT score ≥ 20 is low risk (well controlled)
  static double get mediumRiskThreshold =>
      double.tryParse(dotenv.env['MEDIUM_RISK_THRESHOLD'] ?? '') ??
      16.0; // ACT score 16-19 is medium risk (partially controlled)
  // Below 16 is high risk (poorly controlled)

  // Firebase Collection Names
  static String get usersCollection =>
      dotenv.env['USERS_COLLECTION'] ?? 'users';
  static String get weatherDataCollection =>
      dotenv.env['WEATHER_DATA_COLLECTION'] ?? 'weather_data';
  static String get breathDataCollection =>
      dotenv.env['BREATH_DATA_COLLECTION'] ?? 'breath_data';
  static String get prescriptionsCollection =>
      dotenv.env['PRESCRIPTIONS_COLLECTION'] ?? 'prescriptions';
  static String get environmentConditionsCollection =>
      dotenv.env['ENVIRONMENT_CONDITIONS_COLLECTION'] ??
      'environment_conditions';

  // Shared Preferences Keys
  static const String userKey = 'user';
  static const String userIdKey = 'userId';
  static const String tokenKey = 'token';
  static const String isLoggedInKey = 'isLoggedIn';
}
