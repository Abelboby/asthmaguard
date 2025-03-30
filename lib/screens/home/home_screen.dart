import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../models/user_model.dart';
import '../../models/weather_model.dart';
import '../../models/prescription_model.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../providers/weather_provider.dart';
import '../../widgets/risk_indicator.dart';
import '../../widgets/weather_card.dart';
import '../../widgets/custom_button.dart';
import '../auth/login_screen.dart';
import '../profile/profile_screen.dart';
import '../prescription/prescription_screen.dart';

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

      // Load prescription if user has one
      if (_user!.hasPrescription) {
        _prescription = await _databaseService.getLatestPrescription(_user!.id);
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
        await weatherProvider.refreshWeatherData(_user!);
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

  Future<void> _signOut() async {
    try {
      await _authService.signOut();

      // Reset the provider on sign out
      if (mounted) {
        Provider.of<WeatherProvider>(context, listen: false).reset();
      }

      _navigateToLogin();
    } catch (e) {
      setState(() {
        _errorMessage = 'Error signing out: ${e.toString()}';
      });
    }
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
                              Text(
                                'Current Risk Level',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryTextColor,
                                ),
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
                    WeatherCard(weatherData: weatherData, showTime: false),

                    // Show safety status if user has prescription
                    if (_user != null &&
                        _user!.hasPrescription &&
                        _prescription != null) ...[
                      const SizedBox(height: 24),
                      _buildSafetyCard(weatherData, _prescription!),
                    ],

                    // Show button to add prescription if user doesn't have one
                    if (_user != null && !_user!.hasPrescription) ...[
                      const SizedBox(height: 24),
                      _buildAddPrescriptionCard(),
                    ],
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

  // Helper method to build safety card
  Widget _buildSafetyCard(
      WeatherModel weather, PrescriptionModel prescription) {
    final safetyCheck = prescription.isSafeWeather(weather.temperature,
        weather.humidity, weather.pressure, weather.windSpeed);

    final isOverallSafe = prescription.isOverallSafe(weather.temperature,
        weather.humidity, weather.pressure, weather.windSpeed);

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Doctor\'s Prescription',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryTextColor,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PrescriptionScreen(
                        user: _user!,
                        currentWeather: weather,
                      ),
                    ),
                  );
                },
                child: Text(
                  'View Details',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.linkTextColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isOverallSafe
                      ? AppColors.successColor.withOpacity(0.1)
                      : AppColors.errorColor.withOpacity(0.1),
                ),
                child: Center(
                  child: Icon(
                    isOverallSafe
                        ? Icons.check_circle
                        : Icons.warning_amber_rounded,
                    color: isOverallSafe
                        ? AppColors.successColor
                        : AppColors.errorColor,
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isOverallSafe
                          ? 'Safe Conditions'
                          : 'Warning: Unsafe Conditions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isOverallSafe
                            ? AppColors.successColor
                            : AppColors.errorColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isOverallSafe
                          ? 'Current weather conditions are within your doctor\'s prescribed safe ranges.'
                          : 'Some weather parameters are outside your doctor\'s prescribed safe ranges.',
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
          if (!isOverallSafe) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Unsafe Parameters:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.errorColor,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: safetyCheck.entries
                  .where((entry) => !entry.value)
                  .map((entry) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.errorColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.errorColor.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          _getParameterName(entry.key),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.errorColor,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  String _getParameterName(String key) {
    switch (key) {
      case 'temperature':
        return 'Temperature';
      case 'humidity':
        return 'Humidity';
      case 'pressure':
        return 'Pressure';
      case 'windSpeed':
        return 'Wind Speed';
      default:
        return key;
    }
  }

  Widget _buildAddPrescriptionCard() {
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
                  color: AppColors.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.medical_services_outlined,
                  color: AppColors.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Add Doctor\'s Prescription',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryTextColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Your doctor can prescribe safe ranges for weather parameters based on your asthma condition. This helps the app provide personalized alerts.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 16),
          CustomButton(
            text: 'Add Prescription',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PrescriptionScreen(
                    user: _user!,
                    currentWeather:
                        Provider.of<WeatherProvider>(context, listen: false)
                            .weatherData,
                  ),
                ),
              ).then((_) => _loadUserData()); // Reload data when returning
            },
          ),
        ],
      ),
    );
  }
}
