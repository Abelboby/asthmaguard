import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';

class RiskIndicator extends StatelessWidget {
  final String riskStatus;
  final double? actScore;
  final double size;
  final bool showScore;

  const RiskIndicator({
    Key? key,
    required this.riskStatus,
    this.actScore,
    this.size = 120,
    this.showScore = true,
  }) : super(key: key);

  Color _getRiskColor() {
    if (riskStatus == AppConstants.highRisk) {
      return AppColors.highRiskColor;
    } else if (riskStatus == AppConstants.mediumRisk) {
      return AppColors.mediumRiskColor;
    } else {
      return AppColors.lowRiskColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _getRiskColor().withOpacity(0.1),
            border: Border.all(
              color: _getRiskColor(),
              width: 2.0,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (showScore && actScore != null)
                  Text(
                    actScore!.toStringAsFixed(1),
                    style: TextStyle(
                      color: _getRiskColor(),
                      fontSize: size * 0.25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                Text(
                  riskStatus == AppConstants.highRisk
                      ? 'High Risk'
                      : riskStatus == AppConstants.mediumRisk
                          ? 'Medium Risk'
                          : 'Low Risk',
                  style: TextStyle(
                    color: _getRiskColor(),
                    fontSize: size * 0.12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (riskStatus == AppConstants.highRisk)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Consult a doctor immediately',
              style: TextStyle(
                color: AppColors.highRiskColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}
