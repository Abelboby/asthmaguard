import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/weather_model.dart';
import '../constants/app_colors.dart';

class WeatherCard extends StatelessWidget {
  final WeatherModel weatherData;
  final bool showTime;

  const WeatherCard({
    Key? key,
    required this.weatherData,
    this.showTime = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Weather Conditions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryTextColor,
                  ),
                ),
                if (showTime)
                  Text(
                    DateFormat('MMM d, h:mm a').format(weatherData.timestamp),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.secondaryTextColor,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _buildWeatherParameter(
              'Temperature',
              '${weatherData.temperature.toStringAsFixed(1)}°C',
              Icons.thermostat_outlined,
            ),
            const Divider(),
            _buildWeatherParameter(
              'Humidity',
              '${weatherData.humidity}%',
              Icons.water_drop_outlined,
            ),
            const Divider(),
            _buildWeatherParameter(
              'Pressure',
              '${weatherData.pressure} hPa',
              Icons.speed_outlined,
            ),
            const Divider(),
            _buildWeatherParameter(
              'Wind Speed',
              '${weatherData.windSpeed} m/s',
              Icons.air_outlined,
            ),
            if (weatherData.uvIndex != null) ...[
              const Divider(),
              _buildWeatherParameter(
                'UV Index',
                weatherData.uvIndex!,
                Icons.wb_sunny_outlined,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherParameter(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.primaryColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.secondaryTextColor,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryTextColor,
            ),
          ),
        ],
      ),
    );
  }
}
