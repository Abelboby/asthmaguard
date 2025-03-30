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
                        'Last updated: ${_formatTimeIn12Hour(_breathData!.timestamp)}',
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
              if (_isConnected && _breathData != null) _buildBreathDataCard(),

              const SizedBox(height: 24),

              // Recommendations - Now always visible regardless of connection status
              Text(
                'Recommendations',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryTextColor,
                ),
              ),
              const SizedBox(height: 16),
              _buildRecommendations(),
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
            childAspectRatio: 2.0, // Increased from 1.7 to provide more height
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
      padding: const EdgeInsets.all(12), // Reduced padding from 15
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11, // Reduced from 12
                    color: AppColors.secondaryTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
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

  Color _getStatusColor(String status) {
    if (status.toLowerCase().contains('high')) {
      return AppColors.errorColor;
    } else if (status.toLowerCase().contains('medium')) {
      return AppColors.warningColor;
    } else {
      return AppColors.successColor;
    }
  }

  // Helper method to format time in 12-hour format
  String _formatTimeIn12Hour(DateTime time) {
    final hour = time.hour > 12
        ? time.hour - 12
        : time.hour == 0
            ? 12
            : time.hour;
    final period = time.hour >= 12 ? 'PM' : 'AM';
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  // Building recommendations based on breath data risk status
  Widget _buildRecommendations() {
    // Default recommendations when not connected or no breath data
    List<Map<String, dynamic>> recommendations = [
      {
        'icon': Icons.masks_outlined,
        'title': 'Connect Smart Mask',
        'description': 'Connect your mask to get personalized recommendations.',
        'color': AppColors.primaryColor,
      },
      {
        'icon': Icons.air_outlined,
        'title': 'Check Air Quality',
        'description': 'Be aware of your local air quality conditions.',
        'color': Colors.blue,
      },
      {
        'icon': Icons.health_and_safety_outlined,
        'title': 'Monitor Symptoms',
        'description': 'Keep track of any respiratory symptoms you experience.',
        'color': Colors.purple,
      },
    ];

    // If connected and has breath data, show personalized recommendations
    if (_breathData != null) {
      final riskStatus = _breathData!.riskStatus.toLowerCase();

      if (riskStatus.contains('high')) {
        recommendations = [
          {
            'icon': Icons.medical_services_outlined,
            'title': 'Consult Doctor',
            'description': 'Contact your healthcare provider immediately.',
            'color': AppColors.errorColor,
          },
          {
            'icon': Icons.home_outlined,
            'title': 'Stay Indoors',
            'description': 'Minimize outdoor activities.',
            'color': AppColors.warningColor,
          },
          {
            'icon': Icons.masks_outlined,
            'title': 'Keep Mask On',
            'description':
                'Continue using your smart mask to monitor your condition.',
            'color': AppColors.primaryColor,
          },
        ];
      } else if (riskStatus.contains('medium')) {
        recommendations = [
          {
            'icon': Icons.masks_outlined,
            'title': 'Use Smart Mask',
            'description':
                'Continue monitoring your breath data with the smart mask.',
            'color': AppColors.primaryColor,
          },
          {
            'icon': Icons.air_outlined,
            'title': 'Monitor Environment',
            'description': 'Be aware of air quality in your surroundings.',
            'color': AppColors.warningColor,
          },
          {
            'icon': Icons.medical_services_outlined,
            'title': 'Track Symptoms',
            'description': 'Record any symptoms you experience in a journal.',
            'color': Colors.purple,
          },
        ];
      } else {
        recommendations = [
          {
            'icon': Icons.favorite_outline,
            'title': 'Maintain Wellness',
            'description': 'Continue your healthy routine with the smart mask.',
            'color': AppColors.successColor,
          },
          {
            'icon': Icons.water_drop_outlined,
            'title': 'Stay Hydrated',
            'description': 'Drink plenty of water throughout the day.',
            'color': Colors.blue,
          },
          {
            'icon': Icons.nightlight_outlined,
            'title': 'Quality Sleep',
            'description': 'Ensure you get adequate rest.',
            'color': Colors.indigo,
          },
        ];
      }
    }

    return Column(
      children: recommendations.map((rec) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: (rec['color'] as Color).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                rec['icon'] as IconData,
                color: rec['color'] as Color,
                size: 24,
              ),
            ),
            title: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                rec['title'] as String,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            subtitle: Text(
              rec['description'] as String,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.secondaryTextColor,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
