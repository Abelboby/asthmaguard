import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../constants/app_colors.dart';
import '../../models/user_model.dart';
import '../../models/weather_model.dart';
import '../../models/prescription_model.dart';
import '../../services/weather_service.dart';
import '../../services/database_service.dart';
import '../../widgets/weather_card.dart';
import '../../widgets/custom_button.dart';

class TravelPlannerScreen extends StatefulWidget {
  final UserModel user;
  final PrescriptionModel? prescription;

  const TravelPlannerScreen({
    Key? key,
    required this.user,
    this.prescription,
  }) : super(key: key);

  @override
  State<TravelPlannerScreen> createState() => _TravelPlannerScreenState();
}

class _TravelPlannerScreenState extends State<TravelPlannerScreen> {
  final TextEditingController _cityController = TextEditingController();
  final WeatherService _weatherService = WeatherService();
  final DatabaseService _databaseService = DatabaseService();
  final FocusNode _cityFocusNode = FocusNode();

  // For API-based city suggestions
  List<Map<String, dynamic>> _citySuggestions = [];
  bool _showDropdown = false;
  bool _isLoadingSuggestions = false;

  bool _isLoading = false;
  bool _hasSearched = false;
  String _errorMessage = '';
  WeatherModel? _destinationWeather;

  // API credentials for GeoDB Cities API
  final String _geoDbApiHost = 'wft-geo-db.p.rapidapi.com';
  final String _geoDbApiKey =
      'f14c348ef9mshb9c21c7f6582eddp18dcbejsne33cd2dff5c2'; // Demo key for RapidAPI

  @override
  void initState() {
    super.initState();
    _cityController.addListener(_onSearchTextChanged);
    _cityFocusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _cityController.dispose();
    _cityFocusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_cityFocusNode.hasFocus && _cityController.text.isNotEmpty) {
      setState(() {
        _showDropdown = true;
      });
    } else {
      // Delay closing to allow for selection
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          setState(() {
            _showDropdown = false;
          });
        }
      });
    }
  }

  void _onSearchTextChanged() {
    if (_cityController.text.isEmpty) {
      setState(() {
        _citySuggestions = [];
        _showDropdown = false;
      });
      return;
    }

    // Debounce the API calls to prevent too many requests
    _debouncedFetchCitySuggestions();
  }

  // Variable to store debounce timer
  DateTime? _lastSearchTime;

  // Debounced function to fetch city suggestions
  Future<void> _debouncedFetchCitySuggestions() async {
    final now = DateTime.now();
    _lastSearchTime = now;

    // Wait for 500ms before making the API call
    await Future.delayed(const Duration(milliseconds: 500));

    // Only proceed if this is still the latest request
    if (_lastSearchTime != now) return;

    // Now fetch the suggestions
    if (_cityController.text.length >= 3) {
      _fetchCitySuggestions(_cityController.text);
    }
  }

  // Fetch city suggestions from the API
  Future<void> _fetchCitySuggestions(String query) async {
    if (query.length < 3) return; // Only search if query is at least 3 chars

    setState(() {
      _isLoadingSuggestions = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
            'https://wft-geo-db.p.rapidapi.com/v1/geo/cities?namePrefix=$query&limit=5'),
        headers: {
          'X-RapidAPI-Host': _geoDbApiHost,
          'X-RapidAPI-Key': _geoDbApiKey,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> cities = data['data'] ?? [];

        setState(() {
          _citySuggestions = cities
              .map<Map<String, dynamic>>((city) => {
                    'name': city['name'],
                    'country': city['country'],
                    'region': city['region'],
                  })
              .toList();
          _showDropdown =
              _cityFocusNode.hasFocus && _citySuggestions.isNotEmpty;
          _isLoadingSuggestions = false;
        });
      } else {
        setState(() {
          _isLoadingSuggestions = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingSuggestions = false;
      });
    }
  }

  void _selectCity(Map<String, dynamic> city) {
    setState(() {
      // Format the city name with country for better clarity
      _cityController.text = '${city['name']}, ${city['country']}';
      _showDropdown = false;
    });
    // Optional: trigger search immediately upon selection
    // _searchLocation();
  }

  Future<void> _searchLocation() async {
    if (_cityController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a city name';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _showDropdown = false;
    });

    try {
      // Extract the city name for weather API (remove country if present)
      String cityName = _cityController.text.trim();
      if (cityName.contains(',')) {
        cityName = cityName.split(',')[0].trim();
      }

      // Get weather data for the entered city
      final weatherData = await _weatherService.fetchWeatherByCity(cityName);

      // Process the weather data
      final processedWeatherData =
          await _weatherService.processWeatherData(weatherData);

      // Update with location name
      final weatherWithLocation = WeatherModel(
        temperature: processedWeatherData.temperature,
        humidity: processedWeatherData.humidity,
        pressure: processedWeatherData.pressure,
        windSpeed: processedWeatherData.windSpeed,
        uvIndex: processedWeatherData.uvIndex,
        actScore: processedWeatherData.actScore,
        riskStatus: processedWeatherData.riskStatus,
        timestamp: processedWeatherData.timestamp,
        locationName: _cityController.text.trim(),
      );

      // Save the search to history
      if (widget.user.id.isNotEmpty) {
        await _databaseService.saveWeatherData(
            widget.user.id, weatherWithLocation);
      }

      setState(() {
        _destinationWeather = weatherWithLocation;
        _hasSearched = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching weather data: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Travel Planner',
          style: TextStyle(
            color: AppColors.primaryTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(
          color: AppColors.primaryColor,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Introduction text
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.flight_takeoff,
                          color: AppColors.primaryColor,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Plan Your Trip',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryTextColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Check weather conditions and asthma risk levels at your destination before traveling.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Search field
              Text(
                'Enter Destination',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryTextColor,
                ),
              ),
              const SizedBox(height: 8),

              // City search with dropdown container
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _cityController,
                            focusNode: _cityFocusNode,
                            decoration: InputDecoration(
                              hintText: 'Enter city name (min. 3 characters)',
                              prefixIcon:
                                  const Icon(Icons.location_on_outlined),
                              filled: true,
                              fillColor: Colors.grey[100],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: AppColors.primaryColor,
                                  width: 1.5,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          height: 56,
                          child: CustomButton(
                            text: 'Search',
                            onPressed: _searchLocation,
                            isLoading: _isLoading,
                            width: 100,
                          ),
                        ),
                      ],
                    ),

                    // City suggestions dropdown
                    if (_showDropdown)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(right: 116),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        constraints: const BoxConstraints(
                          maxHeight: 250,
                        ),
                        child: _isLoadingSuggestions
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              )
                            : _citySuggestions.isEmpty &&
                                    _cityController.text.length >= 3
                                ? const Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Text('No cities found'),
                                  )
                                : ListView.builder(
                                    padding: EdgeInsets.zero,
                                    shrinkWrap: true,
                                    itemCount: _citySuggestions.length,
                                    itemBuilder: (context, index) {
                                      final city = _citySuggestions[index];
                                      return Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () => _selectCity(city),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.location_city,
                                                      size: 16,
                                                      color: AppColors
                                                          .primaryColor,
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Text(
                                                        '${city['name']}, ${city['country']}',
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          color: AppColors
                                                              .primaryTextColor,
                                                        ),
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                if (city['region'] != null &&
                                                    city['region']
                                                        .toString()
                                                        .isNotEmpty)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            left: 28.0),
                                                    child: Text(
                                                      city['region'],
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: AppColors
                                                            .secondaryTextColor,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                      ),
                  ],
                ),
              ),

              // Error Message
              if (_errorMessage.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.errorColor.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: AppColors.errorColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage,
                          style: TextStyle(
                            color: AppColors.errorColor,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Results Section
              if (_hasSearched && _destinationWeather != null) ...[
                const SizedBox(height: 32),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Destination Weather',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryTextColor,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: AppColors.secondaryTextColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Today\'s Conditions',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Display weather card
                WeatherCard(
                  weatherData: _destinationWeather!,
                  showTime: true,
                  prescription: widget.prescription,
                ),

                const SizedBox(height: 24),

                // Travel recommendations
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.tips_and_updates,
                            color: AppColors.primaryColor,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Travel Recommendations',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryTextColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildTravelRecommendation(),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTravelRecommendation() {
    if (_destinationWeather == null) return const SizedBox.shrink();

    final riskStatus = _destinationWeather!.riskStatus.toLowerCase();
    final recommendations = <Widget>[];

    // General recommendation for all risk levels
    recommendations.add(
      _buildRecommendationItem(
        icon: Icons.medical_services_outlined,
        title: 'Pack Your Medication',
        description:
            'Always bring your asthma medication and keep it accessible during travel.',
      ),
    );

    // Risk-specific recommendations
    if (riskStatus.contains('high')) {
      recommendations.add(
        _buildRecommendationItem(
          icon: Icons.warning_amber_rounded,
          title: 'Consider Rescheduling',
          description:
              'The destination has high-risk conditions that may trigger severe asthma symptoms.',
          isWarning: true,
        ),
      );
      recommendations.add(
        _buildRecommendationItem(
          icon: Icons.masks_outlined,
          title: 'Wear Protective Mask',
          description:
              'Use your smart mask to filter air if you must travel to this destination.',
        ),
      );
    } else if (riskStatus.contains('medium')) {
      recommendations.add(
        _buildRecommendationItem(
          icon: Icons.hotel_outlined,
          title: 'Indoor Activities',
          description:
              'Plan for more indoor activities, especially during peak hours.',
        ),
      );
      recommendations.add(
        _buildRecommendationItem(
          icon: Icons.schedule_outlined,
          title: 'Track Weather Changes',
          description:
              'Check weather conditions daily as they may change during your stay.',
        ),
      );
    } else {
      recommendations.add(
        _buildRecommendationItem(
          icon: Icons.check_circle_outline,
          title: 'Favorable Conditions',
          description:
              'The destination has good conditions, but maintain your normal asthma management.',
          isGood: true,
        ),
      );
      recommendations.add(
        _buildRecommendationItem(
          icon: Icons.hiking_outlined,
          title: 'Outdoor Activities',
          description:
              'You can enjoy outdoor activities with minimal asthma risk at this location.',
        ),
      );
    }

    return Column(children: recommendations);
  }

  Widget _buildRecommendationItem({
    required IconData icon,
    required String title,
    required String description,
    bool isWarning = false,
    bool isGood = false,
  }) {
    final Color iconColor = isWarning
        ? AppColors.errorColor
        : isGood
            ? AppColors.successColor
            : AppColors.primaryColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryTextColor,
                  ),
                ),
                const SizedBox(height: 4),
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
}
