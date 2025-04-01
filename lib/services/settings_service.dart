import 'package:shared_preferences/shared_preferences.dart';

/// A service for managing application settings with fallback to in-memory storage
/// when SharedPreferences is not available.
class SettingsService {
  // Singleton pattern
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  // In-memory cache as fallback when SharedPreferences is not available
  final Map<String, dynamic> _inMemorySettings = {};
  
  // Flag to track if SharedPreferences is available
  bool _isSharedPreferencesAvailable = true;

  /// Saves a double value to settings.
  /// Falls back to in-memory storage if SharedPreferences fails.
  Future<bool> setDouble(String key, double value) async {
    // Always update the in-memory cache
    _inMemorySettings[key] = value;
    
    // Try to save to SharedPreferences if available
    if (_isSharedPreferencesAvailable) {
      try {
        final prefs = await SharedPreferences.getInstance();
        return await prefs.setDouble(key, value);
      } catch (e) {
        print('Warning: SharedPreferences not available, using in-memory storage: $e');
        _isSharedPreferencesAvailable = false;
        return true; // We still succeeded in saving to in-memory cache
      }
    }
    
    return true; // Saved to in-memory cache
  }

  /// Gets a double value from settings.
  /// Falls back to in-memory storage if SharedPreferences fails.
  Future<double?> getDouble(String key) async {
    // Try to get from SharedPreferences if available
    if (_isSharedPreferencesAvailable) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final value = prefs.getDouble(key);
        if (value != null) {
          _inMemorySettings[key] = value; // Update cache
          return value;
        }
      } catch (e) {
        print('Warning: SharedPreferences not available, using in-memory storage: $e');
        _isSharedPreferencesAvailable = false;
      }
    }
    
    // Fall back to in-memory cache
    return _inMemorySettings[key] as double?;
  }

  /// Saves multiple double values at once.
  /// Falls back to in-memory storage if SharedPreferences fails.
  Future<bool> saveDoubleValues(Map<String, double> values) async {
    bool allSucceeded = true;
    
    // Save each value
    for (final entry in values.entries) {
      final success = await setDouble(entry.key, entry.value);
      if (!success) {
        allSucceeded = false;
      }
    }
    
    return allSucceeded;
  }
} 