import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../models/smart_mask_data_model.dart';

class BreathParameterChart extends StatelessWidget {
  final List<SmartMaskDataModel> data;
  final String title;
  final Color color;
  final String unit;
  final bool isLoading;
  final double Function(SmartMaskDataModel) valueSelector;

  const BreathParameterChart({
    Key? key,
    required this.data,
    required this.title,
    required this.color,
    required this.unit,
    required this.valueSelector,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 220,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
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
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryTextColor,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: isLoading || data.isEmpty
                ? Center(
                    child: isLoading
                        ? CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                          )
                        : Text(
                            'No data available',
                            style: TextStyle(
                              color: AppColors.secondaryTextColor,
                              fontSize: 14,
                            ),
                          ),
                  )
                : Padding(
                    padding: const EdgeInsets.only(bottom: 12, right: 12),
                    child: _buildChart(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    // Filter out invalid values (negative or extreme outliers)
    final filteredData = data.where((item) {
      final value = valueSelector(item);
      return value >= 0 && value < 100; // Basic validation
    }).toList();

    if (filteredData.isEmpty) {
      return Center(
        child: Text(
          'No valid data available',
          style: TextStyle(
            color: AppColors.secondaryTextColor,
            fontSize: 14,
          ),
        ),
      );
    }

    // Get min and max for better visualization
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (var item in filteredData) {
      final value = valueSelector(item);
      if (value < minY) minY = value;
      if (value > maxY) maxY = value;
    }

    // Add padding to the min/max values
    // Use more specific ranges based on the chart type
    if (title.contains('Temperature')) {
      // For breath temperature, use more specific range
      minY = (minY - 2).clamp(20.0, 35.0);
      maxY = (maxY + 2).clamp(minY + 5, 40.0);
    } else if (title.contains('Humidity')) {
      // For breath humidity, use more specific range
      minY = (minY - 5).clamp(30.0, 70.0);
      maxY = (maxY + 5).clamp(minY + 10, 100.0);
    } else {
      // Default padding for other metrics
      minY = (minY - 5).clamp(0, double.infinity);
      maxY = (maxY + 5).clamp(minY + 10, 100.0);
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          horizontalInterval: 10,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.withOpacity(0.15),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= filteredData.length || value.toInt() < 0) {
                  return const SizedBox.shrink();
                }

                // Improved logic to show fewer labels and avoid overlapping
                // Show only start, middle and end for longer datasets
                final int dataLength = filteredData.length;
                bool shouldShowLabel = false;

                if (dataLength <= 5) {
                  // For small datasets, show all points
                  shouldShowLabel = true;
                } else if (dataLength <= 10) {
                  // For medium datasets, show every other point
                  shouldShowLabel =
                      value.toInt() % 2 == 0 || value.toInt() == dataLength - 1;
                } else {
                  // For larger datasets, show only a few strategic points
                  shouldShowLabel = value.toInt() == 0 ||
                      value.toInt() == dataLength - 1 ||
                      value.toInt() == dataLength ~/ 2;
                }

                if (!shouldShowLabel) {
                  return const SizedBox.shrink();
                }

                final time = filteredData[value.toInt()].timestamp;
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    DateFormat('HH:mm').format(time),
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.secondaryTextColor,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                );
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.secondaryTextColor,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                );
              },
              reservedSize: 25,
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.withOpacity(0.2),
              width: 1,
            ),
            left: BorderSide(
              color: Colors.grey.withOpacity(0.2),
              width: 1,
            ),
          ),
        ),
        minX: 0,
        maxX: filteredData.length - 1.0,
        minY: minY,
        maxY: maxY,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.white.withOpacity(0.8),
            tooltipRoundedRadius: 8,
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((spot) {
                final data = filteredData[spot.x.toInt()];
                final value = valueSelector(data);
                return LineTooltipItem(
                  '$value$unit',
                  TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  children: [
                    TextSpan(
                      text: '\n${DateFormat('HH:mm').format(data.timestamp)}',
                      style: TextStyle(
                        color: AppColors.secondaryTextColor,
                        fontWeight: FontWeight.normal,
                        fontSize: 10,
                      ),
                    ),
                  ],
                );
              }).toList();
            },
          ),
          touchCallback:
              (FlTouchEvent event, LineTouchResponse? touchResponse) {},
          handleBuiltInTouches: true,
        ),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(filteredData.length, (index) {
              return FlSpot(
                index.toDouble(),
                valueSelector(filteredData[index]),
              );
            }),
            isCurved: true,
            color: color,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: color.withOpacity(0.15),
            ),
          ),
        ],
      ),
    );
  }
}
