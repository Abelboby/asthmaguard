import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../models/weather_model.dart';
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
      final position = await _determinePosition();

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

      // Determine risk status
      String riskStatus;
      if (actScore >= AppConstants.highRiskThreshold) {
        riskStatus = AppConstants.highRisk;
      } else if (actScore >= AppConstants.mediumRiskThreshold) {
        riskStatus = AppConstants.mediumRisk;
      } else {
        riskStatus = AppConstants.lowRisk;
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

  // Get current location
  Future<Position> _determinePosition() async {
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
}
