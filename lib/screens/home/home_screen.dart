import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../models/user_model.dart';
import '../../models/weather_model.dart';
import '../../services/auth_service.dart';
import '../../services/weather_service.dart';
import '../../services/database_service.dart';
import '../../widgets/risk_indicator.dart';
import '../../widgets/weather_card.dart';
import '../../widgets/custom_button.dart';
import '../auth/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final _authService = AuthService();
  final _weatherService = WeatherService();
  final _databaseService = DatabaseService();

  bool _isLoading = true;
  UserModel? _user;
  WeatherModel? _weatherData;
  String _errorMessage = '';
  String _locationName = 'Loading location...';

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
    _loadUserAndWeatherData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserAndWeatherData() async {
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

      // Get current location coordinates
      final position = await _determinePosition();

      // Get location name
      final locationName =
          await _getLocationName(position.latitude, position.longitude);

      // Fetch weather data
      final weatherData = await _weatherService.fetchWeatherByLocation();
      final processedWeatherData =
          await _weatherService.processWeatherData(weatherData);

      // Save weather data to database
      await _databaseService.saveWeatherData(_user!.id, processedWeatherData);

      if (mounted) {
        setState(() {
          _weatherData = processedWeatherData;
          _locationName = locationName;
          _isLoading = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading data: ${e.toString()}';
          _isLoading = false;
          _locationName = 'Location unavailable';
        });
      }
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
          'Location permissions are permanently denied, cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<String> _getLocationName(double latitude, double longitude) async {
    try {
      final response = await http.get(Uri.parse(
          'https://api.openweathermap.org/geo/1.0/reverse?lat=$latitude&lon=$longitude&limit=1&appid=${AppConstants.weatherApiKey}'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          final String city = data[0]['name'];
          final String country = data[0]['country'];
          return '$city, $country';
        }
      }
      return 'Unknown location';
    } catch (e) {
      return 'Unknown location';
    }
  }

  Future<void> _signOut() async {
    try {
      await _authService.signOut();
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
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _errorMessage.isNotEmpty
              ? _buildErrorView()
              : _buildHomeContent(),
    );
  }

  Widget _buildErrorView() {
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
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.secondaryTextColor,
              ),
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Retry',
              onPressed: _loadUserAndWeatherData,
              width: 200,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: RefreshIndicator(
        onRefresh: _loadUserAndWeatherData,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 120.0,
              floating: false,
              pinned: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'AsthmaGuard',
                  style: TextStyle(
                    color: AppColors.primaryTextColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                centerTitle: false,
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.primaryColor.withOpacity(0.2),
                        AppColors.backgroundColor.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Content
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Location and Date
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: AppColors.primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _locationName,
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.secondaryTextColor,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        DateTime.now().toString().substring(0, 10),
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // User greeting
                  if (_user != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            offset: const Offset(0, 2),
                            blurRadius: 10,
                          ),
                        ],
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white,
                            AppColors.primaryColor.withOpacity(0.1),
                          ],
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primaryColor.withOpacity(0.1),
                              image: _user!.profileImage != null
                                  ? DecorationImage(
                                      image: NetworkImage(_user!.profileImage!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: _user!.profileImage == null
                                ? Center(
                                    child: Text(
                                      _user!.name.substring(0, 1).toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryColor,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hello, ${_user!.name}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryTextColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Here\'s your asthma risk assessment',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.secondaryTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Risk indicator
                  if (_weatherData != null)
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
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white,
                            _getRiskGradientColor(_weatherData!.riskStatus)
                                .withOpacity(0.1),
                          ],
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Current Risk Level',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryTextColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: RiskIndicator(
                              riskStatus: _weatherData!.riskStatus,
                              actScore: _weatherData!.actScore,
                              size: 150,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Weather data
                  if (_weatherData != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Current Weather',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryTextColor,
                          ),
                        ),
                        Text(
                          'Last updated: ' +
                              _weatherData!.timestamp.hour.toString() +
                              ':' +
                              _weatherData!.timestamp.minute
                                  .toString()
                                  .padLeft(2, '0'),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    WeatherCard(weatherData: _weatherData!),
                  ],

                  const SizedBox(height: 24),

                  // Recommendations
                  if (_weatherData != null) ...[
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

                  const SizedBox(height: 24),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRiskGradientColor(String riskStatus) {
    if (riskStatus == AppConstants.highRisk) {
      return AppColors.highRiskColor;
    } else if (riskStatus == AppConstants.mediumRisk) {
      return AppColors.mediumRiskColor;
    } else {
      return AppColors.lowRiskColor;
    }
  }

  Widget _buildRecommendations() {
    if (_weatherData == null) return const SizedBox.shrink();

    // Choose recommendations based on risk status
    List<Map<String, dynamic>> recommendations = [];

    if (_weatherData!.riskStatus == AppConstants.highRisk) {
      recommendations = [
        {
          'icon': Icons.medical_services_outlined,
          'title': 'Consult Doctor',
          'description': 'Contact your healthcare provider immediately.',
        },
        {
          'icon': Icons.home_outlined,
          'title': 'Stay Indoors',
          'description': 'Minimize outdoor activities.',
        },
        {
          'icon': Icons.masks_outlined,
          'title': 'Use Mask',
          'description': 'Use your smart mask when going outside.',
        },
      ];
    } else if (_weatherData!.riskStatus == AppConstants.mediumRisk) {
      recommendations = [
        {
          'icon': Icons.masks_outlined,
          'title': 'Use Mask',
          'description': 'Consider using your smart mask when going outside.',
        },
        {
          'icon': Icons.air_outlined,
          'title': 'Limit Exposure',
          'description': 'Limit time spent in areas with poor air quality.',
        },
        {
          'icon': Icons.medical_services_outlined,
          'title': 'Monitor Symptoms',
          'description': 'Keep track of any symptoms you experience.',
        },
      ];
    } else {
      recommendations = [
        {
          'icon': Icons.favorite_outline,
          'title': 'Stay Active',
          'description': 'Continue your regular activities.',
        },
        {
          'icon': Icons.air_outlined,
          'title': 'Fresh Air',
          'description': 'Enjoy outdoor activities.',
        },
        {
          'icon': Icons.water_drop_outlined,
          'title': 'Stay Hydrated',
          'description': 'Drink plenty of water.',
        },
      ];
    }

    return Container(
      padding: const EdgeInsets.all(16),
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
        children: recommendations.map((rec) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    rec['icon'] as IconData,
                    color: AppColors.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rec['title'] as String,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        rec['description'] as String,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
