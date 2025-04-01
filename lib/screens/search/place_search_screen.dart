import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/place_search_model.dart';
import '../../models/weather_model.dart';
import '../../services/weather_service.dart';
import '../../widgets/weather_card.dart';
import '../../widgets/risk_indicator.dart';
import '../../constants/app_constants.dart';

class PlaceSearchScreen extends StatefulWidget {
  const PlaceSearchScreen({Key? key}) : super(key: key);

  @override
  State<PlaceSearchScreen> createState() => _PlaceSearchScreenState();
}

class _PlaceSearchScreenState extends State<PlaceSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final WeatherService _weatherService = WeatherService();
  final FocusNode _searchFocusNode = FocusNode();

  List<PlaceSearchModel> _searchResults = [];
  bool _isSearching = false;
  bool _isLoadingWeather = false;
  String _errorMessage = '';
  WeatherModel? _selectedPlaceWeather;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // Search for places based on the query
  Future<void> _searchPlaces(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = '';
    });

    try {
      final results = await _weatherService.searchPlaces(query);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error searching places: ${e.toString()}';
        _isSearching = false;
      });
    }
  }

  // Fetch weather for a selected place
  Future<void> _fetchWeatherForPlace(PlaceSearchModel place) async {
    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoadingWeather = true;
      _errorMessage = '';
      _selectedPlaceWeather = null;
      _searchResults = []; // Hide results list
    });

    try {
      // Get weather data from coordinates
      final weatherData = await _weatherService.fetchWeatherByCoordinates(
          place.latitude, place.longitude);

      // Process the weather data with location
      final processedWeather = await _weatherService
          .processWeatherDataWithLocation(weatherData, place.toString());

      setState(() {
        _selectedPlaceWeather = processedWeather;
        _isLoadingWeather = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching weather: ${e.toString()}';
        _isLoadingWeather = false;
      });
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchResults = [];
      _selectedPlaceWeather = null;
      _errorMessage = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Search Places',
          style: TextStyle(
            color: AppColors.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppColors.primaryColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      // Use LayoutBuilder to get screen constraints
      body: LayoutBuilder(
        builder: (context, constraints) {
          return GestureDetector(
            onTap: () =>
                FocusScope.of(context).unfocus(), // Dismiss keyboard on tap
            child: Container(
              height: constraints.maxHeight,
              color: Colors.transparent,
              child: Column(
                children: [
                  // Search bar
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      decoration: InputDecoration(
                        hintText: 'Search for a city...',
                        prefixIcon:
                            Icon(Icons.search, color: AppColors.primaryColor),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: _clearSearch,
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.primaryColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.primaryColor,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      onChanged: (value) {
                        if (value.length > 2) {
                          _searchPlaces(value);
                        } else if (value.isEmpty) {
                          setState(() {
                            _searchResults = [];
                          });
                        }
                      },
                    ),
                  ),

                  // Error message
                  if (_errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: Text(
                          _errorMessage,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ),

                  // Loading indicator for search
                  if (_isSearching)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    ),

                  // Search results
                  if (_searchResults.isNotEmpty && !_isSearching)
                    Expanded(
                      child: Material(
                        elevation: 4,
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                        child: ListView.separated(
                          itemCount: _searchResults.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final place = _searchResults[index];
                            return ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFFE3F2FD),
                                child: Icon(Icons.location_on,
                                    color: Color(0xFF1976D2)),
                              ),
                              title: Text(
                                place.cityName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(place.country),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              onTap: () {
                                _fetchWeatherForPlace(place);
                              },
                            );
                          },
                        ),
                      ),
                    ),

                  // No results message
                  if (_searchResults.isEmpty &&
                      !_isSearching &&
                      _searchController.text.isNotEmpty &&
                      !_isLoadingWeather &&
                      _selectedPlaceWeather == null)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 48,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No places found',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.primaryTextColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try a different search term or check spelling',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: AppColors.secondaryTextColor),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Selected place weather data
                  if (_selectedPlaceWeather != null && !_isLoadingWeather)
                    Expanded(
                      child: MediaQuery.removePadding(
                        context: context,
                        removeTop: true,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                          ),
                          child: ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              // Location header
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.1),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Icon(
                                            Icons.location_on,
                                            color: AppColors.primaryColor,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _selectedPlaceWeather!
                                                        .locationName ??
                                                    'Unknown location',
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                'Last updated: ${_formatTimeIn12Hour(_selectedPlaceWeather!.timestamp)}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors
                                                      .secondaryTextColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Weather information
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildWeatherInfoCard(
                                      'Temperature',
                                      '${_selectedPlaceWeather!.temperature.toStringAsFixed(1)}°C',
                                      Icons.thermostat,
                                      Colors.orange,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildWeatherInfoCard(
                                      'Humidity',
                                      '${_selectedPlaceWeather!.humidity}%',
                                      Icons.water_drop,
                                      Colors.blue,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              Row(
                                children: [
                                  Expanded(
                                    child: _buildWeatherInfoCard(
                                      'Pressure',
                                      '${_selectedPlaceWeather!.pressure} hPa',
                                      Icons.speed,
                                      Colors.purple,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildWeatherInfoCard(
                                      'Wind Speed',
                                      '${_selectedPlaceWeather!.windSpeed} m/s',
                                      Icons.air,
                                      Colors.teal,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),

                              // Risk level card
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Asthma Risk Level',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primaryTextColor,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getRiskColor(
                                                    _selectedPlaceWeather!
                                                        .riskStatus)
                                                .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            _getRiskStatusText(
                                                _selectedPlaceWeather!
                                                    .riskStatus),
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: _getRiskColor(
                                                  _selectedPlaceWeather!
                                                      .riskStatus),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    Center(
                                      child: RiskIndicator(
                                        riskStatus:
                                            _selectedPlaceWeather!.riskStatus,
                                        actScore:
                                            _selectedPlaceWeather!.actScore,
                                        size: 140,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _getRiskDescription(
                                          _selectedPlaceWeather!.riskStatus),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppColors.secondaryTextColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Search new location button
                              ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _selectedPlaceWeather = null;
                                  });
                                  // Focus on search field
                                  Future.delayed(
                                      const Duration(milliseconds: 100), () {
                                    _searchFocusNode.requestFocus();
                                  });
                                },
                                icon: const Icon(Icons.search),
                                label: const Text('Search Another Location'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryColor,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Loading indicator for weather
                  if (_isLoadingWeather)
                    Expanded(
                      child: Container(
                        color: Colors.white,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                  color: AppColors.primaryColor),
                              const SizedBox(height: 24),
                              Text(
                                'Loading weather data...',
                                style: TextStyle(
                                  color: AppColors.primaryColor,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Please wait while we fetch the latest information',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.secondaryTextColor,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWeatherInfoCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
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

  String _getRiskDescription(String riskStatus) {
    if (riskStatus == AppConstants.highRisk) {
      return 'Weather conditions in this area may significantly affect asthma symptoms. Consider consulting your healthcare provider.';
    } else if (riskStatus == AppConstants.mediumRisk) {
      return 'Some weather factors in this location could trigger asthma symptoms in sensitive individuals.';
    } else {
      return 'Weather conditions in this area are generally favorable for people with asthma.';
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
}
