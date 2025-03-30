class WeatherModel {
  final double temperature;
  final int humidity;
  final int pressure;
  final double windSpeed;
  final String? uvIndex;
  final double actScore;
  final String riskStatus;
  final DateTime timestamp;
  final String locationName;

  WeatherModel({
    required this.temperature,
    required this.humidity,
    required this.pressure,
    required this.windSpeed,
    this.uvIndex,
    required this.actScore,
    required this.riskStatus,
    required this.timestamp,
    this.locationName = 'Unknown location',
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    return WeatherModel(
      temperature: (json['temperature'] is String)
          ? double.parse(json['temperature'].toString().replaceAll('°C', ''))
          : (json['temperature'] ?? 0.0).toDouble(),
      humidity: (json['humidity'] is String)
          ? int.parse(json['humidity'].toString().replaceAll('%', ''))
          : (json['humidity'] ?? 0),
      pressure: (json['pressure'] is String)
          ? int.parse(json['pressure'].toString().replaceAll(' hPa', ''))
          : (json['pressure'] ?? 0),
      windSpeed: (json['windSpeed'] is String)
          ? double.parse(json['windSpeed'].toString().replaceAll(' m/s', ''))
          : (json['windSpeed'] ?? 0.0).toDouble(),
      uvIndex: json['uvIndex'],
      actScore: (json['actScore'] is String)
          ? double.parse(json['actScore'].toString())
          : (json['actScore'] ?? 0.0).toDouble(),
      riskStatus: json['riskStatus'] ?? 'Unknown',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      locationName: json['locationName'] ?? 'Unknown location',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'humidity': humidity,
      'pressure': pressure,
      'windSpeed': windSpeed,
      'uvIndex': uvIndex,
      'actScore': actScore,
      'riskStatus': riskStatus,
      'timestamp': timestamp.toIso8601String(),
      'locationName': locationName,
    };
  }

  factory WeatherModel.initial() {
    return WeatherModel(
      temperature: 0.0,
      humidity: 0,
      pressure: 0,
      windSpeed: 0.0,
      uvIndex: 'Low',
      actScore: 0.0,
      riskStatus: 'Unknown',
      timestamp: DateTime.now(),
      locationName: 'Unknown location',
    );
  }
}
