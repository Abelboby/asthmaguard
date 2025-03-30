class PrescriptionModel {
  final double maxTemperature;
  final double minTemperature;
  final int maxHumidity;
  final int minHumidity;
  final int maxPressure;
  final int minPressure;
  final double maxWindSpeed;
  final String doctorName;
  final String notes;
  final DateTime prescribedDate;

  PrescriptionModel({
    required this.maxTemperature,
    required this.minTemperature,
    required this.maxHumidity,
    required this.minHumidity,
    required this.maxPressure,
    required this.minPressure,
    required this.maxWindSpeed,
    required this.doctorName,
    required this.prescribedDate,
    this.notes = '',
  });

  factory PrescriptionModel.fromJson(Map<String, dynamic> json) {
    return PrescriptionModel(
      maxTemperature: (json['maxTemperature'] ?? 35.0).toDouble(),
      minTemperature: (json['minTemperature'] ?? 15.0).toDouble(),
      maxHumidity: json['maxHumidity'] ?? 70,
      minHumidity: json['minHumidity'] ?? 30,
      maxPressure: json['maxPressure'] ?? 1030,
      minPressure: json['minPressure'] ?? 990,
      maxWindSpeed: (json['maxWindSpeed'] ?? 5.0).toDouble(),
      doctorName: json['doctorName'] ?? 'Not specified',
      notes: json['notes'] ?? '',
      prescribedDate: json['prescribedDate'] != null
          ? DateTime.parse(json['prescribedDate'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maxTemperature': maxTemperature,
      'minTemperature': minTemperature,
      'maxHumidity': maxHumidity,
      'minHumidity': minHumidity,
      'maxPressure': maxPressure,
      'minPressure': minPressure,
      'maxWindSpeed': maxWindSpeed,
      'doctorName': doctorName,
      'notes': notes,
      'prescribedDate': prescribedDate.toIso8601String(),
    };
  }

  // Method to check if current weather is safe according to prescription
  Map<String, bool> isSafeWeather(
      double temperature, int humidity, int pressure, double windSpeed) {
    return {
      'temperature':
          temperature >= minTemperature && temperature <= maxTemperature,
      'humidity': humidity >= minHumidity && humidity <= maxHumidity,
      'pressure': pressure >= minPressure && pressure <= maxPressure,
      'windSpeed': windSpeed <= maxWindSpeed,
    };
  }

  // Check if overall conditions are safe
  bool isOverallSafe(
      double temperature, int humidity, int pressure, double windSpeed) {
    final conditions =
        isSafeWeather(temperature, humidity, pressure, windSpeed);
    return !conditions.values.contains(false);
  }
}
