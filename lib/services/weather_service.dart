import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../models/weather_model.dart';
import '../models/place_search_model.dart';
import '../constants/app_constants.dart';

class WeatherService {
  // Fetch weather data by city name
  Future<Map<String, dynamic>> fetchWeatherByCity(String city) async {
    try {
      final response = await http.get(Uri.parse(
          '${AppConstants.weatherApiBaseUrl}/weather?q=$city&appid=${AppConstants.weatherApiKey}'));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load weather data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching weather data: $e');
    }
  }

  // Fetch weather data by user location
  Future<Map<String, dynamic>> fetchWeatherByLocation() async {
    try {
      final position = await determinePosition();

      final response = await http.get(Uri.parse(
          '${AppConstants.weatherApiBaseUrl}/weather?lat=${position.latitude}&lon=${position.longitude}&appid=${AppConstants.weatherApiKey}'));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load weather data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching weather data: $e');
    }
  }

  // New method: Fetch weather data by coordinates
  Future<Map<String, dynamic>> fetchWeatherByCoordinates(
      double latitude, double longitude) async {
    try {
      final response = await http.get(Uri.parse(
          '${AppConstants.weatherApiBaseUrl}/weather?lat=$latitude&lon=$longitude&appid=${AppConstants.weatherApiKey}'));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load weather data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching weather data: $e');
    }
  }

  // New method: Search for places by query
  Future<List<PlaceSearchModel>> searchPlaces(String query) async {
    if (query.trim().isEmpty) {
      return [];
    }

    try {
      final response = await http.get(Uri.parse(
          'https://api.openweathermap.org/geo/1.0/direct?q=$query&limit=5&appid=${AppConstants.weatherApiKey}'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((place) => PlaceSearchModel.fromJson(place)).toList();
      } else {
        throw Exception('Failed to search places: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching places: $e');
    }
  }

  // Get location coordinates
  Future<Position> determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
          'Location permissions are permanently denied, cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition();
  }

  // Get location name from coordinates
  Future<String> getLocationName(double latitude, double longitude) async {
    try {
      final response = await http.get(Uri.parse(
          'https://api.openweathermap.org/geo/1.0/reverse?lat=$latitude&lon=$longitude&limit=1&appid=${AppConstants.weatherApiKey}'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          final String city = data[0]['name'];
          final String country = data[0]['country'];
          return '$city, $country';
        }
      }
      return 'Unknown location';
    } catch (e) {
      return 'Unknown location';
    }
  }

  // Process raw weather data and calculate ACT score
  Future<WeatherModel> processWeatherData(Map<String, dynamic> rawData) async {
    try {
      // Extract required parameters
      final temperature = (rawData['main']['temp'] as num).toDouble() -
          273.15; // Convert from Kelvin to Celsius
      final humidity = (rawData['main']['humidity'] as num).toInt();
      final pressure = (rawData['main']['pressure'] as num).toInt();
      final windSpeed = (rawData['wind']['speed'] as num).toDouble();

      // Use default UV index as it's not available in the free API
      final uvIndex = 'Low';

      // Calculate ACT score (simplified estimation based on sample data)
      // This is a very simplified algorithm - in production we'd use ML model like in the sample code
      double actScore =
          calculateActScore(temperature, humidity, pressure, windSpeed);

      // Determine risk status based on updated thresholds
      // Higher ACT score = better control = lower risk
      String riskStatus;
      if (actScore >= AppConstants.lowRiskThreshold) {
        riskStatus = AppConstants.lowRisk;
      } else if (actScore >= AppConstants.mediumRiskThreshold) {
        riskStatus = AppConstants.mediumRisk;
      } else {
        riskStatus = AppConstants.highRisk;
      }

      return WeatherModel(
        temperature: temperature,
        humidity: humidity,
        pressure: pressure,
        windSpeed: windSpeed,
        uvIndex: uvIndex,
        actScore: actScore,
        riskStatus: riskStatus,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Error processing weather data: $e');
    }
  }

  // New method: Process weather data with a specified location name
  Future<WeatherModel> processWeatherDataWithLocation(
      Map<String, dynamic> rawData, String locationName) async {
    try {
      final weatherModel = await processWeatherData(rawData);

      return WeatherModel(
        temperature: weatherModel.temperature,
        humidity: weatherModel.humidity,
        pressure: weatherModel.pressure,
        windSpeed: weatherModel.windSpeed,
        uvIndex: weatherModel.uvIndex,
        actScore: weatherModel.actScore,
        riskStatus: weatherModel.riskStatus,
        timestamp: weatherModel.timestamp,
        locationName: locationName,
      );
    } catch (e) {
      throw Exception('Error processing weather data with location: $e');
    }
  }

  // Simple implementation of ACT score calculation
  // Note: This is a simplified estimation - in production we'd use ML model
  double calculateActScore(
      double temperature, int humidity, int pressure, double windSpeed) {
    // This is a simplified algorithm based on patterns in sample data
    // Higher temperatures and humidity tend to correlate with lower ACT scores
    // While normal pressure tends to correlate with better scores

    double score = 20.0; // Base score

    // Temperature adjustment
    if (temperature > 30) {
      score -= 2.0;
    } else if (temperature < 20) {
      score -= 1.0;
    }

    // Humidity adjustment
    if (humidity > 80) {
      score -= 1.5;
    } else if (humidity < 40) {
      score += 1.0;
    }

    // Pressure adjustment
    if (pressure < 1000) {
      score -= 1.0;
    } else if (pressure > 1020) {
      score -= 0.5;
    }

    // Wind speed adjustment
    if (windSpeed > 5.0) {
      score -= 1.0;
    }

    // Ensure score is within reasonable bounds
    score = score.clamp(10.0, 30.0);

    return score;
  }
}
