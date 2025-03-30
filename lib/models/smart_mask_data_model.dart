class SmartMaskDataModel {
  final double temperature;
  final double humidity;
  final String triggerLevel;
  final DateTime timestamp;

  SmartMaskDataModel({
    required this.temperature,
    required this.humidity,
    required this.triggerLevel,
    required this.timestamp,
  });

  // Create from raw values
  factory SmartMaskDataModel.fromRawValues({
    required double temperature,
    required double humidity,
    required String triggerLevel,
    DateTime? timestamp,
  }) {
    return SmartMaskDataModel(
      temperature: temperature,
      humidity: humidity,
      triggerLevel: triggerLevel,
      timestamp: timestamp ?? DateTime.now(),
    );
  }

  // Calculate breath score based on the trigger level
  int calculateBreathScore() {
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

  // Create a dummy model for display when no data is available
  factory SmartMaskDataModel.dummy() {
    return SmartMaskDataModel(
      temperature: 0.0,
      humidity: 0.0,
      triggerLevel: 'Unknown',
      timestamp: DateTime.now(),
    );
  }
}
