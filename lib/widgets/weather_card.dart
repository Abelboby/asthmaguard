import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/weather_model.dart';
import '../models/prescription_model.dart';
import '../constants/app_colors.dart';

class WeatherCard extends StatelessWidget {
  final WeatherModel weatherData;
  final bool showTime;
  final PrescriptionModel? prescription;

  const WeatherCard({
    Key? key,
    required this.weatherData,
    this.showTime = true,
    this.prescription,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calculate safety checks if prescription is available
    final safetyCheck = prescription?.isSafeWeather(weatherData.temperature,
        weatherData.humidity, weatherData.pressure, weatherData.windSpeed);
    final isOverallSafe = prescription?.isOverallSafe(weatherData.temperature,
        weatherData.humidity, weatherData.pressure, weatherData.windSpeed);

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

          // Prescription safety status (if available)
          if (prescription != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: (isOverallSafe ?? true)
                              ? AppColors.successColor.withOpacity(0.1)
                              : AppColors.errorColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: (isOverallSafe ?? true)
                                ? AppColors.successColor.withOpacity(0.5)
                                : AppColors.errorColor.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              (isOverallSafe ?? true)
                                  ? Icons.check_circle_outline
                                  : Icons.warning_amber_rounded,
                              color: (isOverallSafe ?? true)
                                  ? AppColors.successColor
                                  : AppColors.errorColor,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              (isOverallSafe ?? true)
                                  ? 'Safe Conditions'
                                  : 'Unsafe Conditions',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: (isOverallSafe ?? true)
                                    ? AppColors.successColor
                                    : AppColors.errorColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Based on doctor\'s prescription',
                          style: TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: AppColors.secondaryTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (!(isOverallSafe ?? true)) ...[
                    const SizedBox(height: 10),
                    _buildPrescriptionRanges(),
                  ],
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
                isSafe: safetyCheck?['temperature'],
                safeRange: prescription != null
                    ? '${prescription!.minTemperature.toStringAsFixed(1)}-${prescription!.maxTemperature.toStringAsFixed(1)}°C'
                    : null,
              ),
              _buildWeatherTile(
                'Humidity',
                '${weatherData.humidity}%',
                Icons.water_drop_outlined,
                Colors.blue,
                isSafe: safetyCheck?['humidity'],
                safeRange: prescription != null
                    ? '${prescription!.minHumidity}-${prescription!.maxHumidity}%'
                    : null,
              ),
              _buildWeatherTile(
                'Pressure',
                '${weatherData.pressure} hPa',
                Icons.speed_outlined,
                Colors.orange,
                isSafe: safetyCheck?['pressure'],
                safeRange: prescription != null
                    ? '${prescription!.minPressure}-${prescription!.maxPressure} hPa'
                    : null,
              ),
              _buildWeatherTile(
                'Wind Speed',
                '${weatherData.windSpeed} m/s',
                Icons.air_outlined,
                Colors.teal,
                isSafe: safetyCheck?['windSpeed'],
                safeRange: prescription != null
                    ? 'Max ${prescription!.maxWindSpeed} m/s'
                    : null,
              ),
              if (weatherData.uvIndex != null &&
                  (prescription == null || safetyCheck?.length == 4))
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
      String label, String value, IconData icon, Color iconColor,
      {bool? isSafe, String? safeRange}) {
    // If no prescription is available, isSafe will be null
    final bool hasSafetyInfo = isSafe != null && safeRange != null;
    // final Color safetyColor =
    //     (isSafe ?? true) ? AppColors.successColor : AppColors.errorColor;

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(15),
        border: hasSafetyInfo && !isSafe
            ? Border.all(
                color: AppColors.errorColor.withOpacity(0.5), width: 1.5)
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: hasSafetyInfo && !isSafe
                  ? AppColors.errorColor.withOpacity(0.1)
                  : iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color:
                  hasSafetyInfo && !isSafe ? AppColors.errorColor : iconColor,
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
                    color: hasSafetyInfo && !isSafe
                        ? AppColors.errorColor
                        : AppColors.primaryTextColor,
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

  Widget _buildPrescriptionRanges() {
    // Check which parameters are unsafe based on prescription
    final safetyCheck = prescription?.isSafeWeather(
      weatherData.temperature,
      weatherData.humidity,
      weatherData.pressure,
      weatherData.windSpeed,
    );

    if (safetyCheck == null || safetyCheck.isEmpty) {
      return const SizedBox.shrink();
    }

    // Get a list of unsafe parameters
    final List<Widget> unsafeParameters = [];

    // Temperature
    if (safetyCheck['temperature'] == false) {
      unsafeParameters.add(
        _buildUnsafeParameter(
          'Temperature',
          '${weatherData.temperature.toStringAsFixed(1)}°C',
          '${prescription!.minTemperature.toStringAsFixed(1)}-${prescription!.maxTemperature.toStringAsFixed(1)}°C',
        ),
      );
    }

    // Humidity
    if (safetyCheck['humidity'] == false) {
      unsafeParameters.add(
        _buildUnsafeParameter(
          'Humidity',
          '${weatherData.humidity}%',
          '${prescription!.minHumidity}-${prescription!.maxHumidity}%',
        ),
      );
    }

    // Pressure
    if (safetyCheck['pressure'] == false) {
      unsafeParameters.add(
        _buildUnsafeParameter(
          'Pressure',
          '${weatherData.pressure} hPa',
          '${prescription!.minPressure}-${prescription!.maxPressure} hPa',
        ),
      );
    }

    // Wind Speed
    if (safetyCheck['windSpeed'] == false) {
      unsafeParameters.add(
        _buildUnsafeParameter(
          'Wind Speed',
          '${weatherData.windSpeed} m/s',
          'Max ${prescription!.maxWindSpeed} m/s',
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.errorColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.errorColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'The following ${unsafeParameters.length == 1 ? 'parameter is' : 'parameters are'} outside the safe ranges:',
            style: TextStyle(
              fontSize: 10,
              fontStyle: FontStyle.italic,
              color: AppColors.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 6),
          ...unsafeParameters,
        ],
      ),
    );
  }

  Widget _buildUnsafeParameter(
      String name, String currentValue, String safeRange) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: AppColors.errorColor,
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            '$name: ',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.primaryTextColor,
            ),
          ),
          Text(
            currentValue,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.errorColor,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '(Safe: $safeRange)',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.normal,
              color: AppColors.secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }
}
