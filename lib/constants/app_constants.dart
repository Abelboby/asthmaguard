class AppConstants {
  // API Constants
  static const String weatherApiBaseUrl =
      'https://api.openweathermap.org/data/2.5';
  static const String weatherApiKey =
      '4dab8e432c434f071363d2f31230cbad'; // Using the sample API key

  // Risk Status Constants
  static const String highRisk = 'High risk - Consult a doctor immediately';
  static const String mediumRisk = 'Medium risk';
  static const String lowRisk = 'Low risk';

  // ACT Score Thresholds - Updated to reflect standard interpretation
  // Lower scores indicate higher risk (poorer control)
  static const double lowRiskThreshold = 20.0;  // ACT score ≥ 20 is low risk (well controlled)
  static const double mediumRiskThreshold = 16.0;  // ACT score 16-19 is medium risk (partially controlled)
  // Below 16 is high risk (poorly controlled)

  // Firebase Collection Names
  static const String usersCollection = 'users';
  static const String weatherDataCollection = 'weather_data';
  static const String breathDataCollection = 'breath_data';
  static const String prescriptionsCollection = 'prescriptions';

  // Shared Preferences Keys
  static const String userKey = 'user';
  static const String userIdKey = 'userId';
  static const String tokenKey = 'token';
  static const String isLoggedInKey = 'isLoggedIn';
}
