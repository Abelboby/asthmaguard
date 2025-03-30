import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../models/breath_data_model.dart';

class SmartMaskScreen extends StatefulWidget {
  const SmartMaskScreen({Key? key}) : super(key: key);

  @override
  State<SmartMaskScreen> createState() => _SmartMaskScreenState();
}

class _SmartMaskScreenState extends State<SmartMaskScreen> {
  bool _isConnected = false;
  bool _isConnecting = false;
  BreathDataModel? _breathData;

  void _connectToSmartMask() {
    if (_isConnecting) return;

    setState(() {
      _isConnecting = true;
    });

    // Simulate connection delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isConnecting = false;
          _isConnected = true;

          // Sample breath data
          _breathData = BreathDataModel(
            breathTemperature: 36.2,
            breathHumidity: 75.0,
            score: 85,
            riskStatus: 'Low Risk',
            timestamp: DateTime.now(),
          );
        });
      }
    });
  }

  void _disconnectSmartMask() {
    if (_isConnecting) return;

    setState(() {
      _isConnecting = true;
    });

    // Simulate disconnection delay
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isConnecting = false;
          _isConnected = false;
          _breathData = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Smart Mask',
          style: TextStyle(
            color: AppColors.primaryTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),

              // Smart Mask Image/Icon
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: _isConnected
                      ? AppColors.primaryColor.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _isConnected
                          ? AppColors.primaryColor.withOpacity(0.2)
                          : Colors.grey.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.masks,
                    size: 80,
                    color: _isConnected ? AppColors.primaryColor : Colors.grey,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Connection Status
              Text(
                _isConnected ? 'Connected' : 'Not Connected',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _isConnected ? AppColors.primaryColor : Colors.grey,
                ),
              ),

              const SizedBox(height: 8),

              // Last updated
              if (_isConnected && _breathData != null)
                Text(
                  'Last updated: ${_breathData!.timestamp.hour}:${_breathData!.timestamp.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.secondaryTextColor,
                  ),
                ),

              const SizedBox(height: 32),

              // Breath Data
              if (_isConnected && _breathData != null) ...[
                _buildBreathDataCard(),
                const SizedBox(height: 32),
              ],

              // Connect Button
              _isConnected
                  ? CustomButton(
                      text: 'Disconnect Smart Mask',
                      onPressed: _disconnectSmartMask,
                      isLoading: _isConnecting,
                      isOutlined: true,
                      color: AppColors.errorColor,
                    )
                  : CustomButton(
                      text: 'Connect Smart Mask',
                      onPressed: _connectToSmartMask,
                      isLoading: _isConnecting,
                    ),

              const SizedBox(height: 16),

              if (!_isConnected)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Connect your AsthmaGuard smart mask to monitor your breath data in real-time and get personalized recommendations.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.secondaryTextColor,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBreathDataCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            AppColors.primaryColor.withOpacity(0.05),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Breath Data',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryTextColor,
            ),
          ),
          const SizedBox(height: 20),

          // Breath Temperature
          _buildBreathDataRow(
            icon: Icons.thermostat_outlined,
            label: 'Breath Temperature',
            value: '${_breathData!.breathTemperature}°C',
          ),
          const SizedBox(height: 12),

          // Breath Humidity
          _buildBreathDataRow(
            icon: Icons.water_drop_outlined,
            label: 'Breath Humidity',
            value: '${_breathData!.breathHumidity}%',
          ),
          const SizedBox(height: 12),

          // Breath Score
          _buildBreathDataRow(
            icon: Icons.favorite_outline,
            label: 'Breath Score',
            value: '${_breathData!.score}/100',
            valueColor: AppColors.primaryColor,
          ),
          const SizedBox(height: 12),

          // Risk Status
          _buildBreathDataRow(
            icon: Icons.shield_outlined,
            label: 'Risk Status',
            value: _breathData!.riskStatus,
            valueColor: _getStatusColor(_breathData!.riskStatus),
          ),
        ],
      ),
    );
  }

  Widget _buildBreathDataRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: AppColors.primaryColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.secondaryTextColor,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: valueColor ?? AppColors.primaryTextColor,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    if (status.toLowerCase().contains('high')) {
      return AppColors.errorColor;
    } else if (status.toLowerCase().contains('medium')) {
      return AppColors.warningColor;
    } else {
      return AppColors.successColor;
    }
  }
}
