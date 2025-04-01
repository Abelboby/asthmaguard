import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/smart_mask_data_model.dart';
import '../services/esp8266_service.dart';
import '../services/settings_service.dart';

class SmartMaskProvider with ChangeNotifier {
  bool _isConnected = false;
  bool _isConnecting = false;
  bool _isDeviceOnline = false;
  SmartMaskDataModel? _smartMaskData;
  SmartMaskDataModel? _previousData;
  List<SmartMaskDataModel> _historicalData = [];
  bool _isLoadingHistoricalData = false;
  
  final ESP8266Service _esp8266Service = ESP8266Service();
  final SettingsService _settingsService = SettingsService();
  StreamSubscription<SmartMaskDataModel>? _dataSubscription;
  Timer? _deviceStatusTimer;
  final int _offlineThresholdSeconds =
      15; // Consider offline after 15 seconds without update

  // For animation flags - these are used by the UI but managed by the provider
  bool _showTemperatureHighlight = false;
  bool _showHumidityHighlight = false;

  // Constructor to load settings
  SmartMaskProvider() {
    _loadTriggerThresholds();
  }

  // Load trigger thresholds from settings service
  Future<void> _loadTriggerThresholds() async {
    try {
      // Load threshold values if they exist (from Firebase first, then local storage)
      final highTemp = await _settingsService.getDouble('high_temp_threshold');
      final lowTemp = await _settingsService.getDouble('low_temp_threshold');
      final highHumidity = await _settingsService.getDouble('high_humidity_threshold');
      final lowHumidity = await _settingsService.getDouble('low_humidity_threshold');
      
      // Update the model's static thresholds if values exist
      SmartMaskDataModel.updateThresholds(
        highTemp: highTemp,
        lowTemp: lowTemp,
        highHumidity: highHumidity,
        lowHumidity: lowHumidity,
      );
      
      print('Loaded trigger thresholds from storage: high temp=${highTemp ?? "default"}, '
           'low temp=${lowTemp ?? "default"}, high humidity=${highHumidity ?? "default"}, '
           'low humidity=${lowHumidity ?? "default"}');
    } catch (e) {
      print('Error loading trigger thresholds: $e');
      // Continue with default values in SmartMaskDataModel
    }
  }

  // Method to refresh settings from cloud
  Future<void> refreshSettings() async {
    await _loadTriggerThresholds();
    notifyListeners();
  }

  // Getters
  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  bool get isDeviceOnline => _isDeviceOnline;
  SmartMaskDataModel? get smartMaskData => _smartMaskData;
  SmartMaskDataModel? get previousData => _previousData;
  List<SmartMaskDataModel> get historicalData => _historicalData;
  bool get isLoadingHistoricalData => _isLoadingHistoricalData;
  bool get showTemperatureHighlight => _showTemperatureHighlight;
  bool get showHumidityHighlight => _showHumidityHighlight;

  // Method to fetch historical data
  Future<void> fetchHistoricalData({int limit = 20}) async {
    if (!_isConnected) return;
    
    _isLoadingHistoricalData = true;
    notifyListeners();
    
    try {
      final data = await _esp8266Service.getHistoricalData(limit: limit);
      
      // Sort data by timestamp (oldest to newest for the graph)
      data.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      _historicalData = data;
    } catch (e) {
      print('Error fetching historical data: $e');
    } finally {
      _isLoadingHistoricalData = false;
      notifyListeners();
    }
  }

  // Method to connect to smart mask
  Future<void> connectToSmartMask(BuildContext context) async {
    if (_isConnecting) return;

    _isConnecting = true;
    notifyListeners();

    try {
      // Try to get initial data
      final data = await _esp8266Service.getLatestData();

      if (data != null) {
        _smartMaskData = data;
        _previousData = data;
        _isConnected = true;
        _isDeviceOnline = _isDataRecent(data.timestamp);

        // Start real-time data stream
        _startDataStream();

        // Start device status monitoring
        _startDeviceStatusMonitoring();
        
        // Fetch historical data for graphs
        await fetchHistoricalData();
      } else {
        // If no data is found
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'No smart mask data found. Please ensure your ESP8266 is sending data.'),
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error connecting to smart mask: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      _isConnecting = false;
      notifyListeners();
    }
  }

  // Method to disconnect from smart mask
  void disconnectSmartMask() {
    if (_isConnecting) return;

    // Stop the real-time data stream
    _dataSubscription?.cancel();
    _dataSubscription = null;

    // Stop the device status monitoring
    _deviceStatusTimer?.cancel();
    _deviceStatusTimer = null;

    _esp8266Service.stopListening();

    _isConnected = false;
    _smartMaskData = null;
    _previousData = null;
    _isDeviceOnline = false;
    _showTemperatureHighlight = false;
    _showHumidityHighlight = false;
    _historicalData = [];

    notifyListeners();
  }

  void _startDataStream() {
    // Start the service listening
    _esp8266Service.startListening();

    // Subscribe to the stream
    _dataSubscription = _esp8266Service.dataStream.listen((data) {
      // Check if values have changed to trigger animations
      if (_smartMaskData != null) {
        _showTemperatureHighlight =
            _smartMaskData!.temperature != data.temperature;
        _showHumidityHighlight = _smartMaskData!.humidity != data.humidity;

        // Store previous data
        _previousData = _smartMaskData;
      }

      _smartMaskData = data;
      _isDeviceOnline = true; // Device is online when we receive new data
      
      // Update historical data when receiving new data
      if (_historicalData.isNotEmpty) {
        // Check if data already exists based on timestamp
        bool dataExists = _historicalData.any((item) => 
            item.timestamp.difference(data.timestamp).inSeconds.abs() < 1);
        
        if (!dataExists) {
          // Add the new data to historical data and keep the list sorted
          _historicalData.add(data);
          _historicalData.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          
          // Keep the list size limited
          if (_historicalData.length > 20) {
            _historicalData.removeAt(0); // Remove oldest
          }
        }
      }

      notifyListeners();
    }, onError: (error) {
      print('Error in ESP8266 data stream: $error');
    });
  }

  // Called by the UI after completing the highlight animation
  void resetHighlights() {
    _showTemperatureHighlight = false;
    _showHumidityHighlight = false;
    notifyListeners();
  }

  // Check if device is online based on the last data timestamp
  bool _isDataRecent(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    return difference.inSeconds < _offlineThresholdSeconds;
  }

  // Start periodic checking of device online status
  void _startDeviceStatusMonitoring() {
    // Cancel any existing timer
    _deviceStatusTimer?.cancel();

    // Check device status every 5 seconds
    _deviceStatusTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_smartMaskData == null) return;

      final isOnline = _isDataRecent(_smartMaskData!.timestamp);
      if (isOnline != _isDeviceOnline) {
        _isDeviceOnline = isOnline;
        notifyListeners();
      }
    });
  }

  // Clean up resources when the provider is disposed
  @override
  void dispose() {
    _dataSubscription?.cancel();
    _deviceStatusTimer?.cancel();
    _esp8266Service.dispose();
    super.dispose();
  }
}
