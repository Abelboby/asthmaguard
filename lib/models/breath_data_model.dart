class BreathDataModel {
  final double breathTemperature;
  final double breathHumidity;
  final int score;
  final String riskStatus;
  final DateTime timestamp;

  BreathDataModel({
    required this.breathTemperature,
    required this.breathHumidity,
    required this.score,
    required this.riskStatus,
    required this.timestamp,
  });

  factory BreathDataModel.fromJson(Map<String, dynamic> json) {
    return BreathDataModel(
      breathTemperature: (json['breathTemperature'] ?? 0.0).toDouble(),
      breathHumidity: (json['breathHumidity'] ?? 0.0).toDouble(),
      score: json['score'] ?? 0,
      riskStatus: json['riskStatus'] ?? 'Unknown',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'breathTemperature': breathTemperature,
      'breathHumidity': breathHumidity,
      'score': score,
      'riskStatus': riskStatus,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory BreathDataModel.initial() {
    return BreathDataModel(
      breathTemperature: 30.0,
      breathHumidity: 70.0,
      score: 0,
      riskStatus: 'Unknown',
      timestamp: DateTime.now(),
    );
  }
} 