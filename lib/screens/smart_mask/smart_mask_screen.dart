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
        title: Text(
          'Smart Mask',
          style: TextStyle(
            color: AppColors.primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              Icons.info_outline,
              color: AppColors.primaryColor,
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Smart Mask helps monitor your breath parameters in real-time'),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Status Card
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 24),
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
                ),
                child: Column(
                  children: [
                    // Smart Mask Image/Icon
                    Container(
                      width: 120,
                      height: 120,
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
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          Icons.masks,
                          size: 60,
                          color: _isConnected
                              ? AppColors.primaryColor
                              : Colors.grey,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Connection Status
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _isConnected
                            ? AppColors.successColor.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _isConnected
                              ? AppColors.successColor.withOpacity(0.3)
                              : Colors.grey.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        _isConnected ? 'Connected' : 'Not Connected',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _isConnected
                              ? AppColors.successColor
                              : Colors.grey,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Last updated
                    if (_isConnected && _breathData != null)
                      Text(
                        'Last updated: ${_breathData!.timestamp.hour}:${_breathData!.timestamp.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.secondaryTextColor,
                        ),
                      ),

                    const SizedBox(height: 20),

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

                    if (!_isConnected)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          'Connect your AsthmaGuard smart mask to monitor your breath data in real-time.',
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

              // Breath Data
              if (_isConnected && _breathData != null) ...[
                _buildBreathDataCard(),
              ],
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Breath Data',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryTextColor,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color:
                      _getStatusColor(_breathData!.riskStatus).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _breathData!.riskStatus,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(_breathData!.riskStatus),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Breath Data Grid
          GridView.count(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            padding: const EdgeInsets.all(0),
            mainAxisSpacing: 15,
            crossAxisSpacing: 15,
            children: [
              _buildBreathDataTile(
                'Breath Temperature',
                '${_breathData!.breathTemperature}°C',
                Icons.thermostat_outlined,
                AppColors.primaryColor,
              ),
              _buildBreathDataTile(
                'Breath Humidity',
                '${_breathData!.breathHumidity}%',
                Icons.water_drop_outlined,
                Colors.blue,
              ),
              _buildBreathDataTile(
                'Breath Score',
                '${_breathData!.score}/100',
                Icons.favorite_outline,
                Colors.red,
              ),
              _buildBreathDataTile(
                'Status',
                _breathData!.riskStatus,
                Icons.shield_outlined,
                _getStatusColor(_breathData!.riskStatus),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBreathDataTile(
    String label,
    String value,
    IconData icon,
    Color iconColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(15),
      ),
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
            ],
          ),
          const SizedBox(height: 10),
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
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: iconColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
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
