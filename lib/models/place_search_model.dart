class PlaceSearchModel {
  final String cityName;
  final String countryCode;
  final String country;
  final double latitude;
  final double longitude;

  PlaceSearchModel({
    required this.cityName,
    required this.countryCode,
    required this.country,
    required this.latitude,
    required this.longitude,
  });

  @override
  String toString() {
    return '$cityName, $country';
  }

  // Factory constructor to create from JSON
  factory PlaceSearchModel.fromJson(Map<String, dynamic> json) {
    return PlaceSearchModel(
      cityName: json['name'] ?? '',
      countryCode: json['country'] ?? '',
      country: json['state'] != null ? '${json['state']}, ${json['country']}' : json['country'] ?? '',
      latitude: (json['lat'] is String) ? double.parse(json['lat']) : (json['lat'] as num).toDouble(),
      longitude: (json['lon'] is String) ? double.parse(json['lon']) : (json['lon'] as num).toDouble(),
    );
  }
} 