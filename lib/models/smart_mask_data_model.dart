class SmartMaskDataModel {
  final double temperature;
  final double humidity;
  final DateTime timestamp;

  // Default thresholds - these can be overridden by user preferences
  static double highTempThreshold = 34.5;  // > 34.5°C is high trigger
  static double lowTempThreshold = 34.0;   // < 34.0°C is low trigger
  static double highHumidityThreshold = 90.0;  // > 90% is high trigger
  static double lowHumidityThreshold = 80.0;   // < 80% is low trigger

  SmartMaskDataModel({
    required this.temperature,
    required this.humidity,
    required this.timestamp,
  });

  // Create from raw values
  factory SmartMaskDataModel.fromRawValues({
    required double temperature,
    required double humidity,
    DateTime? timestamp,
  }) {
    return SmartMaskDataModel(
      temperature: temperature,
      humidity: humidity,
      timestamp: timestamp ?? DateTime.now(),
    );
  }

  // Calculate trigger level based on temperature and humidity
  String calculateTriggerLevel() {
    // Check for high trigger conditions
    if (temperature > highTempThreshold || humidity > highHumidityThreshold) {
      return 'High Triggering Chance';
    }
    
    // Check for medium trigger conditions
    if ((temperature >= lowTempThreshold && temperature <= highTempThreshold) ||
        (humidity >= lowHumidityThreshold && humidity <= highHumidityThreshold)) {
      return 'Medium Triggering Chance';
    }
    
    // Low trigger conditions
    if (temperature < lowTempThreshold && humidity < lowHumidityThreshold) {
      return 'Low Triggering Chance';
    }
    
    // Default to medium if only one parameter is in low range
    return 'Low Triggering Chance';
  }

  // Calculate breath score based on the trigger level
  int calculateBreathScore() {
    String triggerLevel = calculateTriggerLevel();
    switch (triggerLevel) {
      case 'Low Triggering Chance':
        return 85;
      case 'Medium Triggering Chance':
        return 60;
      case 'High Triggering Chance':
        return 30;
      default:
        return 50; // Default for "Uncertain" or any other values
    }
  }

  // Get color status based on trigger level
  String getColorStatus() {
    String triggerLevel = calculateTriggerLevel();
    switch (triggerLevel) {
      case 'Low Triggering Chance':
        return 'green';
      case 'Medium Triggering Chance':
        return 'amber';
      case 'High Triggering Chance':
        return 'red';
      default:
        return 'gray'; // Default for "Uncertain" or any other values
    }
  }

  // Get a formatted version of the trigger level for display
  String getFormattedTriggerLevel() {
    String triggerLevel = calculateTriggerLevel();
    switch (triggerLevel) {
      case 'Low Triggering Chance':
        return 'Low Risk';
      case 'Medium Triggering Chance':
        return 'Medium Risk';
      case 'High Triggering Chance':
        return 'High Risk';
      default:
        return 'Unknown';
    }
  }

  // Update thresholds (can be called from settings)
  static void updateThresholds({
    double? highTemp,
    double? lowTemp,
    double? highHumidity,
    double? lowHumidity,
  }) {
    if (highTemp != null) highTempThreshold = highTemp;
    if (lowTemp != null) lowTempThreshold = lowTemp;
    if (highHumidity != null) highHumidityThreshold = highHumidity;
    if (lowHumidity != null) lowHumidityThreshold = lowHumidity;
  }

  // Create a dummy model for display when no data is available
  factory SmartMaskDataModel.dummy() {
    return SmartMaskDataModel(
      temperature: 0.0,
      humidity: 0.0,
      timestamp: DateTime.now(),
    );
  }
}
