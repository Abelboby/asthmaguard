import 'package:flutter/material.dart';
import 'dart:async';
import '../../constants/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../models/breath_data_model.dart';
import '../../models/smart_mask_data_model.dart';
import '../../services/esp8266_service.dart';

class SmartMaskScreen extends StatefulWidget {
  const SmartMaskScreen({Key? key}) : super(key: key);

  @override
  State<SmartMaskScreen> createState() => _SmartMaskScreenState();
}

class _SmartMaskScreenState extends State<SmartMaskScreen>
    with SingleTickerProviderStateMixin {
  bool _isConnected = false;
  bool _isConnecting = false;
  SmartMaskDataModel? _smartMaskData;
  SmartMaskDataModel? _previousData;
  final ESP8266Service _esp8266Service = ESP8266Service();
  StreamSubscription<SmartMaskDataModel>? _dataSubscription;

  // For animations
  late AnimationController _animationController;
  bool _showTemperatureHighlight = false;
  bool _showHumidityHighlight = false;

  // For device online status checking
  bool _isDeviceOnline = true;
  Timer? _deviceStatusTimer;
  final int _offlineThresholdSeconds =
      15; // Consider offline after 15 seconds without update

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _showTemperatureHighlight = false;
          _showHumidityHighlight = false;
        });
        _animationController.reset();
      }
    });
  }

  @override
  void dispose() {
    _dataSubscription?.cancel();
    _deviceStatusTimer?.cancel();
    _animationController.dispose();
    _esp8266Service.dispose();
    super.dispose();
  }

  void _connectToSmartMask() {
    if (_isConnecting) return;

    setState(() {
      _isConnecting = true;
    });

    // Try to get initial data
    _esp8266Service.getLatestData().then((data) {
      if (data != null) {
        setState(() {
          _smartMaskData = data;
          _previousData = data; // Initialize previous data
          _isConnected = true;
          _isConnecting = false;
          _isDeviceOnline = _isDataRecent(data.timestamp);
        });

        // Start real-time data stream
        _startDataStream();

        // Start device status monitoring
        _startDeviceStatusMonitoring();
      } else {
        // If no data is found
        setState(() {
          _isConnecting = false;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'No smart mask data found. Please ensure your ESP8266 is sending data.'),
              duration: Duration(seconds: 4),
            ),
          );
        });
      }
    }).catchError((error) {
      setState(() {
        _isConnecting = false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error connecting to smart mask: $error'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      });
    });
  }

  void _startDataStream() {
    // Start the service listening
    _esp8266Service.startListening();

    // Subscribe to the stream
    _dataSubscription = _esp8266Service.dataStream.listen((data) {
      if (mounted) {
        setState(() {
          // Check if values have changed to trigger animations
          if (_smartMaskData != null) {
            _showTemperatureHighlight =
                _smartMaskData!.temperature != data.temperature;
            _showHumidityHighlight = _smartMaskData!.humidity != data.humidity;

            // Store previous data
            _previousData = _smartMaskData;
          }

          _smartMaskData = data;
          _isDeviceOnline = true; // Device is online when we receive new data
        });

        // Start animation if values changed
        if (_showTemperatureHighlight || _showHumidityHighlight) {
          _animationController.forward();
        }
      }
    }, onError: (error) {
      print('Error in ESP8266 data stream: $error');
    });
  }

  // Check if device is online based on the last data timestamp
  bool _isDataRecent(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    return difference.inSeconds < _offlineThresholdSeconds;
  }

  // Start periodic checking of device online status
  void _startDeviceStatusMonitoring() {
    // Cancel any existing timer
    _deviceStatusTimer?.cancel();

    // Check device status every 5 seconds
    _deviceStatusTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted || _smartMaskData == null) return;

      final isOnline = _isDataRecent(_smartMaskData!.timestamp);
      if (isOnline != _isDeviceOnline) {
        setState(() {
          _isDeviceOnline = isOnline;
        });

        // Show notification when device goes offline
        if (!isOnline) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                  'Smart Mask appears to be offline. No data received in the last 15 seconds.'),
              backgroundColor: AppColors.warningColor,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    });
  }

  void _disconnectSmartMask() {
    if (_isConnecting) return;

    // Stop the real-time data stream
    _dataSubscription?.cancel();
    _dataSubscription = null;

    // Stop the device status monitoring
    _deviceStatusTimer?.cancel();
    _deviceStatusTimer = null;

    _esp8266Service.stopListening();

    setState(() {
      _isConnected = false;
      _smartMaskData = null;
      _previousData = null;
      _isDeviceOnline = false;
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
                        _isConnected ? 'Connected to ESP8266' : 'Not Connected',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _isConnected
                              ? AppColors.successColor
                              : Colors.grey,
                        ),
                      ),
                    ),

                    // Device Online Status indicator (if connected)
                    if (_isConnected) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: _isDeviceOnline
                                  ? AppColors.successColor
                                  : AppColors.errorColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _isDeviceOnline
                                ? 'Device Online'
                                : 'Device Offline',
                            style: TextStyle(
                              fontSize: 12,
                              color: _isDeviceOnline
                                  ? AppColors.successColor
                                  : AppColors.errorColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 8),

                    // Last updated
                    if (_isConnected && _smartMaskData != null)
                      Text(
                        'Last updated: ${_formatTimeIn12Hour(_smartMaskData!.timestamp)}',
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
                          'Connect your AsthmaGuard smart mask to monitor your breath data in real-time from the ESP8266 device.',
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
              if (_isConnected && _smartMaskData != null)
                _buildSmartMaskDataCard(),

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

  Widget _buildSmartMaskDataCard() {
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
                  color: _getStatusColor(
                          _smartMaskData!.getFormattedTriggerLevel())
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _smartMaskData!.getFormattedTriggerLevel(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(
                        _smartMaskData!.getFormattedTriggerLevel()),
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
                '${_smartMaskData!.temperature.toStringAsFixed(1)}°C',
                Icons.thermostat_outlined,
                AppColors.primaryColor, // Teal blue
                showHighlight: _showTemperatureHighlight,
                previousValue: _previousData != null
                    ? '${_previousData!.temperature.toStringAsFixed(1)}°C'
                    : null,
              ),
              _buildBreathDataTile(
                'Breath Humidity',
                '${_smartMaskData!.humidity.toStringAsFixed(1)}%',
                Icons.water_drop_outlined,
                AppColors.primaryColor, // Teal blue
                showHighlight: _showHumidityHighlight,
                previousValue: _previousData != null
                    ? '${_previousData!.humidity.toStringAsFixed(1)}%'
                    : null,
              ),
              _buildBreathDataTile(
                'Status',
                _smartMaskData!.getFormattedTriggerLevel(),
                Icons.shield_outlined,
                _getStatusColor(_smartMaskData!.getFormattedTriggerLevel()),
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
    Color iconColor, {
    bool showHighlight = false,
    String? previousValue,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(15),
        border: showHighlight
            ? Border.all(
                color: AppColors.primaryColor,
                width: 2.0,
              )
            : null,
        boxShadow: showHighlight
            ? [
                BoxShadow(
                  color: AppColors.primaryColor.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                )
              ]
            : null,
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
                // Animated value change
                showHighlight && previousValue != null
                    ? Stack(
                        children: [
                          // Old value (fading out)
                          Opacity(
                            opacity: 1.0 - _animationController.value,
                            child: Text(
                              previousValue,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: iconColor.withOpacity(0.5),
                              ),
                            ),
                          ),
                          // New value (fading in)
                          Opacity(
                            opacity: _animationController.value,
                            child: Text(
                              value,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: iconColor,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Text(
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
        'color': AppColors.primaryColor, // Teal blue
      },
      {
        'icon': Icons.air_outlined,
        'title': 'Check Air Quality',
        'description': 'Be aware of your local air quality conditions.',
        'color': AppColors.primaryColor, // Teal blue
      },
      {
        'icon': Icons.health_and_safety_outlined,
        'title': 'Monitor Symptoms',
        'description': 'Keep track of any respiratory symptoms you experience.',
        'color': AppColors.primaryColor, // Teal blue
      },
    ];

    // If connected and has breath data, show personalized recommendations
    if (_smartMaskData != null) {
      final riskStatus =
          _smartMaskData!.getFormattedTriggerLevel().toLowerCase();

      if (riskStatus.contains('high')) {
        recommendations = [
          {
            'icon': Icons.medical_services_outlined,
            'title': 'Consult Doctor',
            'description': 'Contact your healthcare provider immediately.',
            'color': AppColors.errorColor, // Keep red for error
          },
          {
            'icon': Icons.home_outlined,
            'title': 'Stay Indoors',
            'description': 'Minimize outdoor activities.',
            'color': AppColors.primaryColor, // Teal blue
          },
          {
            'icon': Icons.masks_outlined,
            'title': 'Keep Mask On',
            'description':
                'Continue using your smart mask to monitor your condition.',
            'color': AppColors.primaryColor, // Teal blue
          },
        ];
      } else if (riskStatus.contains('medium')) {
        recommendations = [
          {
            'icon': Icons.masks_outlined,
            'title': 'Use Smart Mask',
            'description':
                'Continue monitoring your breath data with the smart mask.',
            'color': AppColors.primaryColor, // Teal blue
          },
          {
            'icon': Icons.air_outlined,
            'title': 'Monitor Environment',
            'description': 'Be aware of air quality in your surroundings.',
            'color': AppColors.primaryColor, // Teal blue
          },
          {
            'icon': Icons.medical_services_outlined,
            'title': 'Track Symptoms',
            'description': 'Record any symptoms you experience in a journal.',
            'color': AppColors.primaryColor, // Teal blue
          },
        ];
      } else {
        recommendations = [
          {
            'icon': Icons.favorite_outline,
            'title': 'Maintain Wellness',
            'description': 'Continue your healthy routine with the smart mask.',
            'color': AppColors.successColor, // Teal blue
          },
          {
            'icon': Icons.water_drop_outlined,
            'title': 'Stay Hydrated',
            'description': 'Drink plenty of water throughout the day.',
            'color': AppColors.primaryColor, // Teal blue
          },
          {
            'icon': Icons.nightlight_outlined,
            'title': 'Quality Sleep',
            'description': 'Ensure you get adequate rest.',
            'color': AppColors.primaryColor, // Teal blue
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
