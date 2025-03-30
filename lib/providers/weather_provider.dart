import 'package:flutter/foundation.dart';
import '../models/weather_model.dart';
import '../models/user_model.dart';
import '../services/weather_service.dart';
import '../services/database_service.dart';

class WeatherProvider with ChangeNotifier {
  final WeatherService _weatherService = WeatherService();
  final DatabaseService _databaseService = DatabaseService();

  WeatherModel? _weatherData;
  bool _isLoading = false;
  String _errorMessage = '';
  bool _hasInitialLoad = false;

  // Getters
  WeatherModel? get weatherData => _weatherData;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get hasData => _weatherData != null;
  bool get hasInitialLoad => _hasInitialLoad;

  // Initialize with data from Firebase if available
  Future<void> initialize(UserModel user) async {
    if (_hasInitialLoad) return; // Skip if already initialized

    _isLoading = true;
    notifyListeners();

    try {
      // Try to get latest data from Firebase
      final latestWeatherData =
          await _databaseService.getLatestWeatherData(user.id);

      if (latestWeatherData != null) {
        _weatherData = latestWeatherData;
        _hasInitialLoad = true;
        _errorMessage = '';
      }
    } catch (e) {
      _errorMessage = 'Error initializing weather data: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch fresh data from API and update Firebase
  Future<void> refreshWeatherData(UserModel user) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      // Get location and weather from API
      final position = await _weatherService.determinePosition();
      final locationName = await _weatherService.getLocationName(
          position.latitude, position.longitude);

      // Fetch and process weather data
      final weatherData = await _weatherService.fetchWeatherByLocation();
      final processedWeatherData =
          await _weatherService.processWeatherData(weatherData);

      // Add location to the weather model
      final weatherWithLocation = WeatherModel(
        temperature: processedWeatherData.temperature,
        humidity: processedWeatherData.humidity,
        pressure: processedWeatherData.pressure,
        windSpeed: processedWeatherData.windSpeed,
        uvIndex: processedWeatherData.uvIndex,
        actScore: processedWeatherData.actScore,
        riskStatus: processedWeatherData.riskStatus,
        timestamp: processedWeatherData.timestamp,
        locationName: locationName,
      );

      // Save to Firebase
      await _databaseService.saveWeatherData(user.id, weatherWithLocation);

      // Update local state
      _weatherData = weatherWithLocation;
      _hasInitialLoad = true;
    } catch (e) {
      _errorMessage = 'Error refreshing weather data: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Reset provider state (useful for logout)
  void reset() {
    _weatherData = null;
    _isLoading = false;
    _errorMessage = '';
    _hasInitialLoad = false;
    notifyListeners();
  }
}
