import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../models/user_model.dart';
import '../../models/weather_model.dart';
import '../../services/auth_service.dart';
import '../../providers/weather_provider.dart';
import '../../widgets/risk_indicator.dart';
import '../../widgets/weather_card.dart';
import '../../widgets/custom_button.dart';
import '../auth/login_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final _authService = AuthService();
  bool _isLoading = true;
  UserModel? _user;
  String _errorMessage = '';

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
                    margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
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
                  ],

                  const SizedBox(height: 24),

                  // Recommendations
                  if (weatherData != null) ...[
                    Text(
                      'Recommendations',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildRecommendations(weatherData),
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

  Widget _buildRecommendations(WeatherModel weatherData) {
    List<Map<String, dynamic>> recommendations = [];

    if (weatherData.riskStatus == AppConstants.highRisk) {
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
          'title': 'Use Mask',
          'description': 'Use your smart mask when going outside.',
          'color': AppColors.primaryColor,
        },
      ];
    } else if (weatherData.riskStatus == AppConstants.mediumRisk) {
      recommendations = [
        {
          'icon': Icons.masks_outlined,
          'title': 'Use Mask',
          'description': 'Consider using your smart mask when going outside.',
          'color': AppColors.primaryColor,
        },
        {
          'icon': Icons.air_outlined,
          'title': 'Limit Exposure',
          'description': 'Limit time spent in areas with poor air quality.',
          'color': AppColors.warningColor,
        },
        {
          'icon': Icons.medical_services_outlined,
          'title': 'Monitor Symptoms',
          'description': 'Keep track of any symptoms you experience.',
          'color': Colors.purple,
        },
      ];
    } else {
      recommendations = [
        {
          'icon': Icons.favorite_outline,
          'title': 'Stay Active',
          'description': 'Continue your regular activities.',
          'color': AppColors.successColor,
        },
        {
          'icon': Icons.air_outlined,
          'title': 'Fresh Air',
          'description': 'Enjoy outdoor activities.',
          'color': Colors.blue,
        },
        {
          'icon': Icons.water_drop_outlined,
          'title': 'Stay Hydrated',
          'description': 'Drink plenty of water.',
          'color': Colors.cyan,
        },
      ];
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
}
