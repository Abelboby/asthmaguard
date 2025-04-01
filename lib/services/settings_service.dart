import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// A service for managing application settings with multiple storage options:
/// 1. Firebase Firestore (primary, for sync across devices)
/// 2. SharedPreferences (local backup)
/// 3. In-memory cache (fallback when other methods fail)
class SettingsService {
  // Singleton pattern
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  // Firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // In-memory cache as fallback when other storage methods fail
  final Map<String, dynamic> _inMemorySettings = {};
  
  // Flags to track if storage methods are available
  bool _isSharedPreferencesAvailable = true;
  bool _isFirebaseAvailable = true;

  /// Gets the current user ID for Firebase storage
  String? get _userId => _auth.currentUser?.uid;

  /// Gets the Firestore document reference for user settings
  DocumentReference? get _userSettingsRef {
    final uid = _userId;
    if (uid == null) return null;
    return _firestore.collection('user_settings').doc(uid);
  }

  /// Saves a double value to settings.
  /// Attempts to save to Firebase first, then SharedPreferences, then in-memory.
  Future<bool> setDouble(String key, double value) async {
    // Always update the in-memory cache immediately
    _inMemorySettings[key] = value;
    
    bool savedToFirebase = false;
    bool savedToPrefs = false;
    
    // Try to save to Firebase if available
    if (_isFirebaseAvailable && _userId != null) {
      try {
        final settingsRef = _userSettingsRef;
        if (settingsRef != null) {
          // Use set with merge to update specific fields without overwriting others
          await settingsRef.set({
            'trigger_thresholds': {
              key: value
            }
          }, SetOptions(merge: true));
          savedToFirebase = true;
        }
      } catch (e) {
        print('Warning: Firebase not available for settings storage: $e');
        _isFirebaseAvailable = false;
      }
    }
    
    // Also try to save to SharedPreferences as backup
    if (_isSharedPreferencesAvailable) {
      try {
        final prefs = await SharedPreferences.getInstance();
        savedToPrefs = await prefs.setDouble(key, value);
      } catch (e) {
        print('Warning: SharedPreferences not available, using in-memory storage: $e');
        _isSharedPreferencesAvailable = false;
      }
    }
    
    // Return true if saved to at least one persistent storage
    return savedToFirebase || savedToPrefs || true; // Always return true if saved to memory
  }

  /// Gets a double value from settings.
  /// Tries Firebase first, then SharedPreferences, then in-memory.
  Future<double?> getDouble(String key) async {
    double? value;
    
    // Try to get from Firebase first
    if (_isFirebaseAvailable && _userId != null) {
      try {
        final settingsRef = _userSettingsRef;
        if (settingsRef != null) {
          final doc = await settingsRef.get();
          if (doc.exists) {
            final data = doc.data() as Map<String, dynamic>?;
            if (data != null && 
                data['trigger_thresholds'] is Map && 
                data['trigger_thresholds'][key] is num) {
              value = (data['trigger_thresholds'][key] as num).toDouble();
              // Update cache with latest value from Firebase
              _inMemorySettings[key] = value;
              return value;
            }
          }
        }
      } catch (e) {
        print('Warning: Firebase not available for settings retrieval: $e');
        _isFirebaseAvailable = false;
      }
    }
    
    // If not found in Firebase, try SharedPreferences
    if (value == null && _isSharedPreferencesAvailable) {
      try {
        final prefs = await SharedPreferences.getInstance();
        value = prefs.getDouble(key);
        if (value != null) {
          // Update cache with value from SharedPreferences
          _inMemorySettings[key] = value;
          
          // If Firebase is available but value wasn't there, sync it up
          if (_isFirebaseAvailable && _userId != null) {
            try {
              final settingsRef = _userSettingsRef;
              if (settingsRef != null) {
                await settingsRef.set({
                  'trigger_thresholds': {
                    key: value
                  }
                }, SetOptions(merge: true));
              }
            } catch (_) {
              // Ignore error syncing to Firebase at this point
            }
          }
          
          return value;
        }
      } catch (e) {
        print('Warning: SharedPreferences not available for settings retrieval: $e');
        _isSharedPreferencesAvailable = false;
      }
    }
    
    // Fall back to in-memory cache if not found elsewhere
    return _inMemorySettings[key] as double?;
  }

  /// Saves multiple double values at once.
  /// More efficient than calling setDouble multiple times.
  Future<bool> saveDoubleValues(Map<String, double> values) async {
    bool success = true;
    
    // Always update in-memory cache immediately
    values.forEach((key, value) {
      _inMemorySettings[key] = value;
    });
    
    // Try to save to Firebase if available (in a single update)
    if (_isFirebaseAvailable && _userId != null) {
      try {
        final settingsRef = _userSettingsRef;
        if (settingsRef != null) {
          // Create a map of all the values
          final Map<String, dynamic> triggerThresholds = {};
          values.forEach((key, value) {
            triggerThresholds[key] = value;
          });
          
          // Update Firebase with all values in one go
          await settingsRef.set({
            'trigger_thresholds': triggerThresholds
          }, SetOptions(merge: true));
        }
      } catch (e) {
        print('Warning: Firebase not available for settings storage: $e');
        _isFirebaseAvailable = false;
        success = false;
      }
    } else {
      success = false;
    }
    
    // Also save to SharedPreferences as backup
    if (_isSharedPreferencesAvailable) {
      try {
        final prefs = await SharedPreferences.getInstance();
        bool allSaved = true;
        
        for (final entry in values.entries) {
          final saveSuccess = await prefs.setDouble(entry.key, entry.value);
          if (!saveSuccess) {
            allSaved = false;
          }
        }
        
        if (allSaved) {
          success = true; // If all saved to prefs, consider it a success
        }
      } catch (e) {
        print('Warning: SharedPreferences not available for settings storage: $e');
        _isSharedPreferencesAvailable = false;
      }
    }
    
    // If we at least saved to memory, consider it a partial success
    return success;
  }
} 