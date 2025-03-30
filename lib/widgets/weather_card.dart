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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (showTime)
                  Text(
                    'Weather Conditions',
                    style: TextStyle(
                      fontSize: 16,
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
          ),

          // Weather grid
          GridView.count(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            crossAxisCount: 2,
            childAspectRatio: 2.2,
            padding: const EdgeInsets.all(15),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: [
              _buildWeatherTile(
                'Temperature',
                '${weatherData.temperature.toStringAsFixed(1)}°C',
                Icons.thermostat_outlined,
                AppColors.primaryColor,
              ),
              _buildWeatherTile(
                'Humidity',
                '${weatherData.humidity}%',
                Icons.water_drop_outlined,
                Colors.blue,
              ),
              _buildWeatherTile(
                'Pressure',
                '${weatherData.pressure} hPa',
                Icons.speed_outlined,
                Colors.orange,
              ),
              _buildWeatherTile(
                'Wind Speed',
                '${weatherData.windSpeed} m/s',
                Icons.air_outlined,
                Colors.teal,
              ),
              if (weatherData.uvIndex != null)
                _buildWeatherTile(
                  'UV Index',
                  weatherData.uvIndex!,
                  Icons.wb_sunny_outlined,
                  Colors.amber,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherTile(
      String label, String value, IconData icon, Color iconColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(15),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.secondaryTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryTextColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
