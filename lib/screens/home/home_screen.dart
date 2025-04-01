import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../models/user_model.dart';
import '../../models/weather_model.dart';
import '../../models/prescription_model.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/weather_service.dart';
import '../../providers/weather_provider.dart';
import '../../widgets/risk_indicator.dart';
import '../../widgets/weather_card.dart';
import '../../widgets/custom_button.dart';
import '../auth/login_screen.dart';
import '../profile/profile_screen.dart';
import '../prescription/prescription_screen.dart';
import '../main_layout.dart';
import '../smart_mask/smart_mask_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final _authService = AuthService();
  final _databaseService = DatabaseService();
  bool _isLoading = true;
  UserModel? _user;
  String _errorMessage = '';
  PrescriptionModel? _prescription;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );
    _loadUserData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Show risk-based warning for smart mask usage
  void _showSmartMaskRecommendation(BuildContext context, String riskStatus) {
    // Get the weather provider
    final weatherProvider =
        Provider.of<WeatherProvider>(context, listen: false);

    // Check if we should show the popup using the provider's method
    if (!weatherProvider.shouldShowRiskPopup(riskStatus)) {
      return;
    }

    // Mark that we've shown the popup for this session in the provider
    weatherProvider.setRiskPopupShown(true);

    // Delay showing the popup to allow the UI to render first
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.masks,
                  color: riskStatus == AppConstants.highRisk
                      ? AppColors.errorColor
                      : AppColors.warningColor,
                ),
                const SizedBox(width: 10),
                Text(
                  riskStatus == AppConstants.highRisk
                      ? 'High Risk Detected'
                      : 'Medium Risk Detected',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: riskStatus == AppConstants.highRisk
                        ? AppColors.errorColor
                        : AppColors.warningColor,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  riskStatus == AppConstants.highRisk
                      ? 'Current weather conditions pose a high risk to your respiratory health.'
                      : 'Current weather conditions may affect your respiratory health.',
                  style: const TextStyle(
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  riskStatus == AppConstants.highRisk
                      ? 'It is strongly recommended to use your Smart Mask for real-time monitoring of your breath data.'
                      : 'Using your Smart Mask would be beneficial to monitor your breath parameters.',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Later'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  // Navigate to Smart Mask screen
                  _navigateToSmartMaskScreen();
                },
                child: Text(
                  riskStatus == AppConstants.highRisk
                      ? 'Connect Now'
                      : 'Connect Mask',
                ),
              ),
            ],
          );
        },
      );
    });
  }

  // Helper to navigate to Smart Mask screen
  void _navigateToSmartMaskScreen() {
    // Navigate to MainLayout with Smart Mask tab (index 1) selected
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
          builder: (context) => const MainLayout(initialIndex: 1)),
      (route) => false, // Remove all previous routes
    );
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Load user data
      final user = await _authService.getUserModel();
      if (user == null) {
        // User not found, navigate to login
        _navigateToLogin();
        return;
      }

      _user = user;

      // Load prescription if user has one (check both flags for compatibility)
      if (_user!.hasPrescription || _user!.hasEnvironmentConditions) {
        _prescription =
            await _databaseService.getLatestEnvironmentConditions(_user!.id);
      }

      // Initialize the weather provider with user data
      if (mounted) {
        final weatherProvider =
            Provider.of<WeatherProvider>(context, listen: false);

        // If the provider has no data, initialize it from Firebase
        if (!weatherProvider.hasData) {
          await weatherProvider.initialize(_user!);

          // If still no data after initialization, refresh from API
          if (!weatherProvider.hasData) {
            await weatherProvider.refreshWeatherData(_user!);
          }
        }

        // Check risk level and show smart mask recommendation if needed
        if (weatherProvider.hasData) {
          _showSmartMaskRecommendation(
              context, weatherProvider.weatherData!.riskStatus);
        }

        setState(() {
          _isLoading = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading data: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  // Handle pull-to-refresh - now uses the provider
  Future<void> _handlePullToRefresh() async {
    try {
      if (_user != null) {
        final weatherProvider =
            Provider.of<WeatherProvider>(context, listen: false);

        // Store the previous risk status before refresh
        String? previousRiskStatus = weatherProvider.hasData
            ? weatherProvider.weatherData?.riskStatus
            : null;

        // Refresh weather data
        await weatherProvider.refreshWeatherData(_user!);

        // If risk level changed to medium or high AND previous risk was different (or low),
        // reset the popup shown flag to allow showing it again
        if (weatherProvider.hasData &&
            previousRiskStatus != null &&
            previousRiskStatus != weatherProvider.weatherData?.riskStatus &&
            (weatherProvider.weatherData?.riskStatus ==
                    AppConstants.mediumRisk ||
                weatherProvider.weatherData?.riskStatus ==
                    AppConstants.highRisk)) {
          // Reset the flag in the provider
          weatherProvider.setRiskPopupShown(false);

          // Show recommendation with new risk status
          if (mounted && weatherProvider.weatherData != null) {
            _showSmartMaskRecommendation(
                context, weatherProvider.weatherData!.riskStatus);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error refreshing data: ${e.toString()}')),
        );
      }
    }
    return Future.value();
  }

  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get the weather provider
    final weatherProvider = Provider.of<WeatherProvider>(context);
    final weatherData = weatherProvider.weatherData;
    final isProviderLoading = weatherProvider.isLoading;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: _isLoading || isProviderLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _errorMessage.isNotEmpty || weatherProvider.errorMessage.isNotEmpty
              ? _buildErrorView(weatherProvider.errorMessage)
              : _buildHomeContent(weatherData),
    );
  }

  Widget _buildErrorView(String providerError) {
    final errorMsg = _errorMessage.isNotEmpty ? _errorMessage : providerError;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: AppColors.errorColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading Data',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryTextColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMsg,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.secondaryTextColor,
              ),
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Retry',
              onPressed: _loadUserData,
              width: 200,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeContent(WeatherModel? weatherData) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: RefreshIndicator(
        onRefresh: _handlePullToRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 80.0,
              floating: true,
              pinned: true,
              snap: false,
              backgroundColor: AppColors.backgroundColor,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                title: Text(
                  'AsthmaGuard',
                  style: TextStyle(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                centerTitle: false,
                background: Container(
                  decoration: BoxDecoration(
                    color: AppColors.backgroundColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileScreen(),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 16, bottom: 16),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryColor.withOpacity(0.1),
                      border: Border.all(
                        color: AppColors.primaryColor.withOpacity(0.3),
                        width: 2,
                      ),
                      image: _user?.profileImage != null
                          ? DecorationImage(
                              image: NetworkImage(_user!.profileImage!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _user?.profileImage == null
                        ? Center(
                            child: Text(
                              _user != null && _user!.name.isNotEmpty
                                  ? _user!.name.substring(0, 1).toUpperCase()
                                  : 'A',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryColor,
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
              ],
            ),

            // Content
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Combined Greeting and Location Card
                  if (_user != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 24, top: 16),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Greeting
                          Text(
                            'Hello, ${_user!.name}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryTextColor,
                            ),
                          ),
                          const SizedBox(height: 4),

                          // Location with icon
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 16,
                                color: AppColors.primaryColor,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  weatherData?.locationName ??
                                      'Loading location...',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.secondaryTextColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          // Risk assessment message
                          Text(
                            'Pull down to refresh data anytime',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Risk indicator
                  if (weatherData != null)
                    Container(
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Current Risk Level',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryTextColor,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.info_outline,
                                      size: 18,
                                      color: AppColors.secondaryTextColor,
                                    ),
                                    padding: const EdgeInsets.all(4),
                                    constraints: const BoxConstraints(),
                                    onPressed: () => _showActScoreInfo(context),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _getRiskColor(weatherData.riskStatus)
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _getRiskStatusText(weatherData.riskStatus),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        _getRiskColor(weatherData.riskStatus),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Center(
                            child: RiskIndicator(
                              riskStatus: weatherData.riskStatus,
                              actScore: weatherData.actScore,
                              size: 150,
                            ),
                          ),
                          const SizedBox(height: 15),
                          // Add explanatory text about ACT score
                          Center(
                            child: Text(
                              'Based on environmental factors that affect your breathing',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: AppColors.secondaryTextColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (weatherData.riskStatus == AppConstants.highRisk)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 16),
                              decoration: BoxDecoration(
                                color: AppColors.errorColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.errorColor.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    color: AppColors.errorColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Please consult your doctor immediately',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.errorColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Weather data
                  if (weatherData != null) ...[
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
                        Text(
                          'Last updated: ${_formatTimeIn12Hour(weatherData.timestamp)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    WeatherCard(
                      weatherData: weatherData,
                      showTime: false,
                      prescription: _user != null &&
                              (_user!.hasPrescription ||
                                  _user!.hasEnvironmentConditions)
                          ? _prescription
                          : null,
                    ),

                    // Add a button to view prescription details if it exists
                    if (_user != null &&
                        (_user!.hasPrescription ||
                            _user!.hasEnvironmentConditions) &&
                        _prescription != null) ...[
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PrescriptionScreen(
                                  user: _user!,
                                  currentWeather: weatherData,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.thermostat_outlined, size: 16),
                          label: const Text('View Environment Conditions'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.linkTextColor,
                          ),
                        ),
                      ),
                    ],
                  ],

                  // Always show Environment Conditions card
                  const SizedBox(height: 24),
                  if (_user != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Environment Conditions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryTextColor,
                          ),
                        ),
                        if (_user!.hasPrescription ||
                            _user!.hasEnvironmentConditions)
                          Text(
                            'Status: Configured',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.successColor,
                              fontWeight: FontWeight.w500,
                            ),
                          )
                        else
                          Text(
                            'Status: Not configured',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.secondaryTextColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildAddPrescriptionCard(),
                  ],

                  const SizedBox(height: 24),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRiskColor(String riskStatus) {
    if (riskStatus == AppConstants.highRisk) {
      return AppColors.highRiskColor;
    } else if (riskStatus == AppConstants.mediumRisk) {
      return AppColors.mediumRiskColor;
    } else {
      return AppColors.lowRiskColor;
    }
  }

  String _getRiskStatusText(String riskStatus) {
    if (riskStatus == AppConstants.highRisk) {
      return 'High Risk';
    } else if (riskStatus == AppConstants.mediumRisk) {
      return 'Medium Risk';
    } else {
      return 'Low Risk';
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

  Widget _buildAddPrescriptionCard() {
    bool hasEnvironmentConditions = _user != null &&
        (_user!.hasPrescription || _user!.hasEnvironmentConditions);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: hasEnvironmentConditions
                      ? AppColors.successColor.withOpacity(0.1)
                      : AppColors.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.medical_services_outlined,
                  color: hasEnvironmentConditions
                      ? AppColors.successColor
                      : AppColors.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasEnvironmentConditions
                          ? 'Your Environment Conditions'
                          : 'Set Environment Conditions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryTextColor,
                      ),
                    ),
                    if (hasEnvironmentConditions && _prescription != null)
                      Text(
                        'Temperature: ${_prescription!.minTemperature}°C - ${_prescription!.maxTemperature}°C, Humidity: ${_prescription!.minHumidity}% - ${_prescription!.maxHumidity}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.secondaryTextColor,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            hasEnvironmentConditions
                ? 'These settings help determine if current weather conditions are safe for your asthma.'
                : 'Set safe ranges for weather parameters based on your asthma condition. This helps the app provide personalized alerts.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: hasEnvironmentConditions ? 'Update' : 'Quick Setup',
                  onPressed: _showQuickSetupDialog,
                  isOutlined: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  text: hasEnvironmentConditions
                      ? 'View Details'
                      : 'Advanced Setup',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PrescriptionScreen(
                          user: _user!,
                          currentWeather: Provider.of<WeatherProvider>(context,
                                  listen: false)
                              .weatherData,
                        ),
                      ),
                    ).then(
                        (_) => _loadUserData()); // Reload data when returning
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Show quick setup dialog for environment conditions
  void _showQuickSetupDialog() {
    if (_user == null) return;

    bool hasExistingConditions = _prescription != null;

    // Controllers for the quick setup
    final tempMinController = TextEditingController(
        text: hasExistingConditions
            ? _prescription!.minTemperature.toString()
            : '15.0');
    final tempMaxController = TextEditingController(
        text: hasExistingConditions
            ? _prescription!.maxTemperature.toString()
            : '30.0');
    final humidityMinController = TextEditingController(
        text: hasExistingConditions
            ? _prescription!.minHumidity.toString()
            : '30');
    final humidityMaxController = TextEditingController(
        text: hasExistingConditions
            ? _prescription!.maxHumidity.toString()
            : '70');
    final doctorNameController = TextEditingController(
        text: hasExistingConditions ? _prescription!.doctorName : 'Self');

    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.thermostat_outlined,
                color: AppColors.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(hasExistingConditions
                  ? 'Update Environment Conditions'
                  : 'Quick Environment Setup'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Temperature Range
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: tempMinController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Min Temp (°C)',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: tempMaxController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Max Temp (°C)',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Humidity Range
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: humidityMinController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Min Humidity (%)',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: humidityMaxController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Max Humidity (%)',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Set by name
                TextField(
                  controller: doctorNameController,
                  decoration: const InputDecoration(
                    labelText: 'Set By (Optional)',
                    hintText: 'Your name or doctor\'s name',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),

                const SizedBox(height: 12),
                Text(
                  hasExistingConditions
                      ? 'Updating will overwrite your current settings.'
                      : 'Default pressure and wind values will be used. Use Advanced Setup for more options.',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: AppColors.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      try {
                        // Validate inputs
                        final minTemp = double.parse(tempMinController.text);
                        final maxTemp = double.parse(tempMaxController.text);
                        final minHumidity =
                            int.parse(humidityMinController.text);
                        final maxHumidity =
                            int.parse(humidityMaxController.text);

                        // Set default values for other parameters
                        const minPressure = 990;
                        const maxPressure = 1030;
                        const maxWindSpeed = 5.0;

                        // Show saving state
                        setState(() {
                          isSaving = true;
                        });

                        // Create prescription model
                        final prescription = PrescriptionModel(
                          minTemperature: minTemp,
                          maxTemperature: maxTemp,
                          minHumidity: minHumidity,
                          maxHumidity: maxHumidity,
                          minPressure: minPressure,
                          maxPressure: maxPressure,
                          maxWindSpeed: maxWindSpeed,
                          doctorName: doctorNameController.text.isNotEmpty
                              ? doctorNameController.text
                              : 'Self',
                          notes: 'Quick setup from home screen.',
                          prescribedDate: DateTime.now(),
                        );

                        // Save to database
                        await _databaseService.saveEnvironmentConditions(
                            _user!.id, prescription);

                        // Close dialog
                        if (mounted) {
                          Navigator.of(context).pop();

                          // Show success message
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(hasExistingConditions
                                    ? 'Environment conditions updated!'
                                    : 'Environment conditions saved!')),
                          );

                          // Reload data
                          _loadUserData();
                        }
                      } catch (e) {
                        // Show error
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: ${e.toString()}')),
                          );
                          setState(() {
                            isSaving = false;
                          });
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ))
                  : Text(hasExistingConditions ? 'Update' : 'Save'),
            ),
          ],
        ),
      ),
    ).then((_) {
      // Dispose controllers
      tempMinController.dispose();
      tempMaxController.dispose();
      humidityMinController.dispose();
      humidityMaxController.dispose();
      doctorNameController.dispose();
    });
  }

  void _showActScoreInfo(BuildContext context) {
    // Updated ACT score information dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.analytics_outlined,
              color: AppColors.primaryColor,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text('About ACT Score'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What is ACT Score?',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.primaryTextColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'The Asthma Control Test (ACT) Score is a standardized measurement used to assess how well a patient\'s asthma is controlled. In AsthmaGuard, we calculate a modified ACT score based on environmental factors that are known to influence asthma symptoms.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.secondaryTextColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'How is it calculated?',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.primaryTextColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Our ACT score considers multiple environmental factors including:',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.secondaryTextColor,
                ),
              ),
              const SizedBox(height: 8),
              _buildFactorItem('Temperature',
                  'Extreme hot or cold temperatures can trigger asthma'),
              _buildFactorItem(
                  'Humidity', 'Very high or low humidity affects breathing'),
              _buildFactorItem('Air Pressure',
                  'Rapid changes in barometric pressure can trigger symptoms'),
              _buildFactorItem('Wind Speed',
                  'High winds can increase pollutants and allergens in the air'),
              const SizedBox(height: 16),
              Text(
                'Score Interpretation',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.primaryTextColor,
                ),
              ),
              const SizedBox(height: 8),
              _buildScoreRange(
                '5-15',
                'High Risk',
                'Poorly controlled asthma. Consult your doctor immediately.',
                AppColors.highRiskColor,
              ),
              const SizedBox(height: 8),
              _buildScoreRange(
                '16-19',
                'Medium Risk',
                'Partially controlled asthma. Monitor your condition closely.',
                AppColors.mediumRiskColor,
              ),
              const SizedBox(height: 8),
              _buildScoreRange(
                '20-25',
                'Low Risk',
                'Well-controlled asthma under current conditions.',
                AppColors.lowRiskColor,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildFactorItem(String factor, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.circle,
            size: 8,
            color: AppColors.primaryColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  factor,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.primaryTextColor,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreRange(
      String range, String risk, String description, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Text(
            range,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                risk,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: color,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.secondaryTextColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
