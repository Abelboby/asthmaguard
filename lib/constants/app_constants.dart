class AppConstants {
  // API Constants
  static const String weatherApiBaseUrl = 'https://api.openweathermap.org/data/2.5';
  static const String weatherApiKey = '4dab8e432c434f071363d2f31230cbad'; // Using the sample API key

  // Risk Status Constants
  static const String highRisk = 'High risk - Consult a doctor immediately';
  static const String mediumRisk = 'Medium risk';
  static const String lowRisk = 'Low risk';

  // ACT Score Thresholds
  static const double highRiskThreshold = 25.0;
  static const double mediumRiskThreshold = 20.0;

  // Firebase Collection Names
  static const String usersCollection = 'users';
  static const String weatherDataCollection = 'weather_data';
  static const String breathDataCollection = 'breath_data';
  
  // Shared Preferences Keys
  static const String userKey = 'user';
  static const String userIdKey = 'userId';
  static const String tokenKey = 'token';
  static const String isLoggedInKey = 'isLoggedIn';
} 