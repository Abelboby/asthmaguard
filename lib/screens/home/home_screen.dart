import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../constants/app_colors.dart';
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

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  final _weatherService = WeatherService();
  final _databaseService = DatabaseService();

  bool _isLoading = true;
  UserModel? _user;
  WeatherModel? _weatherData;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadUserAndWeatherData();
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

      // Fetch weather data
      final weatherData = await _weatherService.fetchWeatherByLocation();
      final processedWeatherData =
          await _weatherService.processWeatherData(weatherData);

      // Save weather data to database
      await _databaseService.saveWeatherData(_user!.id, processedWeatherData);

      setState(() {
        _weatherData = processedWeatherData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading data: ${e.toString()}';
        _isLoading = false;
      });
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
      appBar: AppBar(
        title: const Text(
          'AsthmaGuard',
          style: TextStyle(
            color: AppColors.primaryTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.primaryTextColor),
            onPressed: _signOut,
          ),
        ],
      ),
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
    return RefreshIndicator(
      onRefresh: _loadUserAndWeatherData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User greeting
            if (_user != null)
              Text(
                'Hello, ${_user!.name}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryTextColor,
                ),
              ),
            const SizedBox(height: 8),
            Text(
              'Here\'s your asthma risk assessment',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.secondaryTextColor,
              ),
            ),

            const SizedBox(height: 24),

            // Risk indicator
            if (_weatherData != null)
              Center(
                child: RiskIndicator(
                  riskStatus: _weatherData!.riskStatus,
                  actScore: _weatherData!.actScore,
                  size: 160,
                ),
              ),

            const SizedBox(height: 32),

            // Weather data
            if (_weatherData != null) ...[
              Text(
                'Current Weather Conditions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryTextColor,
                ),
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

            // Smart Mask connection (placeholder)
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.bluetooth,
                          color: AppColors.primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Smart Mask',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryTextColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Connect your smart mask to monitor breath data in real-time.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    CustomButton(
                      text: 'Connect Mask',
                      onPressed: () {
                        // Placeholder for mask connection feature
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Smart mask feature coming soon!'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendations() {
    if (_weatherData == null) return const SizedBox.shrink();

    // Choose recommendations based on risk status
    List<Map<String, dynamic>> recommendations = [];

    if (_weatherData!.riskStatus ==
        'High risk - Consult a doctor immediately') {
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
    } else if (_weatherData!.riskStatus == 'Medium risk') {
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

    return Column(
      children: recommendations.map((rec) {
        return ListTile(
          leading: Icon(
            rec['icon'] as IconData,
            color: AppColors.primaryColor,
          ),
          title: Text(
            rec['title'] as String,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(rec['description'] as String),
          contentPadding: EdgeInsets.zero,
        );
      }).toList(),
    );
  }
}
