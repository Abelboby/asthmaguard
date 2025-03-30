import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../models/smart_mask_data_model.dart';

class ESP8266Service {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot>? _subscription;
  final StreamController<SmartMaskDataModel> _dataStreamController =
      StreamController<SmartMaskDataModel>.broadcast();

  // Public stream that components can listen to
  Stream<SmartMaskDataModel> get dataStream => _dataStreamController.stream;

  // Start listening to ESP8266 data
  void startListening() {
    if (_subscription != null) return;

    _subscription = _firestore
        .collection('esp8266')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        try {
          final doc = snapshot.docs.first;
          final data = doc.data() as Map<String, dynamic>;

          // Parse data, handling both direct values and nested field structures
          final maskData = _parseESP8266Data(data);
          _dataStreamController.add(maskData);
        } catch (e) {
          print('Error parsing ESP8266 data: $e');
        }
      }
    }, onError: (error) {
      print('Error getting ESP8266 data: $error');
    });
  }

  // Get latest data once
  Future<SmartMaskDataModel?> getLatestData() async {
    try {
      final snapshot = await _firestore
          .collection('esp8266')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final data = doc.data();
        return _parseESP8266Data(data);
      }
      return null;
    } catch (e) {
      print('Error getting latest ESP8266 data: $e');
      return null;
    }
  }

  // Get historical data
  Future<List<SmartMaskDataModel>> getHistoricalData({int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection('esp8266')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return _parseESP8266Data(data);
      }).toList();
    } catch (e) {
      print('Error getting historical ESP8266 data: $e');
      return [];
    }
  }

  // Helper method to parse ESP8266 data from Firestore
  SmartMaskDataModel _parseESP8266Data(Map<String, dynamic> data) {
    // Check the format and extract data accordingly
    double temperature;
    double humidity;
    String triggerLevel;
    DateTime timestamp;

    // Handle temperature - could be direct value or nested
    if (data['temperature'] is double || data['temperature'] is int) {
      temperature = (data['temperature'] as num).toDouble();
    } else if (data['temperature'] is Map) {
      temperature = (data['temperature']['doubleValue'] as num).toDouble();
    } else {
      temperature = 0.0;
    }

    // Handle humidity - could be direct value or nested
    if (data['humidity'] is double || data['humidity'] is int) {
      humidity = (data['humidity'] as num).toDouble();
    } else if (data['humidity'] is Map) {
      humidity = (data['humidity']['doubleValue'] as num).toDouble();
    } else {
      humidity = 0.0;
    }

    // Handle triggerLevel - could be direct string or nested
    if (data['triggerLevel'] is String) {
      triggerLevel = data['triggerLevel'];
    } else if (data['triggerLevel'] is Map) {
      triggerLevel = data['triggerLevel']['stringValue'] ?? 'Unknown';
    } else {
      triggerLevel = 'Unknown';
    }

    // Handle timestamp - could be direct Timestamp, String or nested
    if (data['timestamp'] is Timestamp) {
      timestamp = (data['timestamp'] as Timestamp).toDate();
    } else if (data['timestamp'] is String) {
      timestamp = DateTime.parse(data['timestamp']);
    } else if (data['timestamp'] is Map &&
        data['timestamp']['timestampValue'] != null) {
      timestamp = DateTime.parse(data['timestamp']['timestampValue']);
    } else {
      timestamp = DateTime.now();
    }

    return SmartMaskDataModel(
      temperature: temperature,
      humidity: humidity,
      triggerLevel: triggerLevel,
      timestamp: timestamp,
    );
  }

  // Stop listening to ESP8266 data
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }

  // Dispose resources
  void dispose() {
    stopListening();
    _dataStreamController.close();
  }
}
