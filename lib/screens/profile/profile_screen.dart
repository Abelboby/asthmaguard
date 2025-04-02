import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../../widgets/custom_button.dart';
import '../../providers/smart_mask_provider.dart';
import '../../providers/weather_provider.dart';
import '../auth/login_screen.dart';
import '../prescription/prescription_screen.dart';
import 'trigger_threshold_settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  UserModel? _user;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final user = await _authService.getUserModel();
      setState(() {
        _user = user;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading user data: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _signOut() async {
    try {
      setState(() {
        _isLoading = true;
      });
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error signing out: ${e.toString()}';
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
          'Profile',
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
            icon: Icon(Icons.refresh, color: AppColors.primaryColor),
            onPressed: _loadUserData,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? _buildErrorView()
              : _buildProfileContent(),
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
              'Error Loading Profile',
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
              onPressed: _loadUserData,
              width: 200,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent() {
    if (_user == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'No user data found',
                style: TextStyle(
                  fontSize: 18,
                  color: AppColors.secondaryTextColor,
                ),
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: 'Sign Out',
                onPressed: _signOut,
                width: 200,
              ),
            ],
          ),
        ),
      );
    }

    // Access providers for real-time data
    final smartMaskProvider = Provider.of<SmartMaskProvider>(context);
    final weatherProvider = Provider.of<WeatherProvider>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 16),

          // Profile Header Card
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
                // Profile Image
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryColor.withOpacity(0.1),
                    border: Border.all(
                      color: AppColors.primaryColor.withOpacity(0.3),
                      width: 3,
                    ),
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
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        )
                      : null,
                ),

                const SizedBox(height: 16),

                // User Name
                Text(
                  _user!.name,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryTextColor,
                  ),
                ),

                const SizedBox(height: 4),

                // User Email
                Text(
                  _user!.email,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),

          // User Info Card - Updated with real-time data
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Account Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryTextColor,
                  ),
                ),
                const SizedBox(height: 16),

                // User ID
                _buildInfoTile(
                  icon: Icons.perm_identity_outlined,
                  label: 'User ID',
                  value: _user!.id.substring(0, 8) + '...',
                  iconColor: Colors.indigo,
                ),

                // Smart Mask Status - Now using real-time data from provider
                _buildInfoTile(
                  icon: Icons.masks_outlined,
                  label: 'Smart Mask',
                  value: smartMaskProvider.isConnected
                      ? smartMaskProvider.isDeviceOnline
                          ? 'Connected - Online'
                          : 'Connected - Offline'
                      : 'Not Connected',
                  valueColor: smartMaskProvider.isConnected
                      ? smartMaskProvider.isDeviceOnline
                          ? AppColors.successColor
                          : Colors.orange
                      : AppColors.secondaryTextColor,
                  iconColor: AppColors.primaryColor,
                ),

                // Last Breath Data - Show only if connected
                if (smartMaskProvider.isConnected &&
                    smartMaskProvider.smartMaskData != null)
                  _buildInfoTile(
                    icon: Icons.monitor_heart_outlined,
                    label: 'Last Breath Data',
                    value: 'Temp: ${smartMaskProvider.smartMaskData!.temperature.toStringAsFixed(1)}°C, ' +
                        'Humidity: ${smartMaskProvider.smartMaskData!.humidity.toStringAsFixed(1)}%',
                    iconColor: Colors.teal,
                  ),

                // Location - Using data from the weather provider
                _buildInfoTile(
                  icon: Icons.location_on_outlined,
                  label: 'Location',
                  value: weatherProvider.hasData &&
                          weatherProvider.weatherData!.locationName.isNotEmpty
                      ? weatherProvider.weatherData!.locationName
                      : _user!.location ?? 'Not Set',
                  iconColor: Colors.orange,
                ),

                // Last Weather Update - Show only if weather data exists
                if (weatherProvider.hasData)
                  _buildInfoTile(
                    icon: Icons.update,
                    label: 'Last Weather Update',
                    value: _formatTimeIn12Hour(
                        weatherProvider.weatherData!.timestamp),
                    iconColor: Colors.blue,
                  ),
              ],
            ),
          ),

          // Account Settings Card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryTextColor,
                  ),
                ),
                const SizedBox(height: 16),

                // Doctor Prescription Settings
                _buildSettingsTile(
                  icon: Icons.thermostat_outlined,
                  label: 'Environment Conditions',
                  iconColor: Colors.purple,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PrescriptionScreen(
                          user: _user!,
                          currentWeather: weatherProvider
                              .weatherData, // Pass weather data from provider
                        ),
                      ),
                    );
                  },
                ),

                // Edit Profile Button
                _buildSettingsTile(
                  icon: Icons.edit_outlined,
                  label: 'Edit Profile',
                  iconColor: AppColors.primaryColor,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Edit Profile feature coming soon!'),
                      ),
                    );
                  },
                ),

                // // Change Password Button
                // _buildSettingsTile(
                //   icon: Icons.lock_outline,
                //   label: 'Change Password',
                //   iconColor: Colors.amber,
                //   onTap: () {
                //     ScaffoldMessenger.of(context).showSnackBar(
                //       const SnackBar(
                //         content: Text('Change Password feature coming soon!'),
                //       ),
                //     );
                //   },
                // ),

                // // Notifications Button
                // _buildSettingsTile(
                //   icon: Icons.notifications_outlined,
                //   label: 'Notifications',
                //   iconColor: Colors.deepPurple,
                //   onTap: () {
                //     ScaffoldMessenger.of(context).showSnackBar(
                //       const SnackBar(
                //         content: Text('Notifications feature coming soon!'),
                //       ),
                //     );
                //   },
                // ),

                // Trigger Threshold Settings
                _buildSettingsTile(
                  icon: Icons.tune,
                  label: 'Asthma Trigger Thresholds',
                  iconColor: Colors.orange,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const TriggerThresholdSettingsScreen(),
                      ),
                    );
                  },
                ),

                // Privacy Button
                // _buildSettingsTile(
                //   icon: Icons.privacy_tip_outlined,
                //   label: 'Privacy & Security',
                //   iconColor: Colors.teal,
                //   onTap: () {
                //     ScaffoldMessenger.of(context).showSnackBar(
                //       const SnackBar(
                //         content:
                //             Text('Privacy & Security feature coming soon!'),
                //       ),
                //     );
                //   },
                // ),
              ],
            ),
          ),

          // Smart Mask Status Card - New
          smartMaskProvider.isConnected
              ? Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Smart Mask Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Smart Mask Status
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: smartMaskProvider.isDeviceOnline
                              ? AppColors.successColor.withOpacity(0.1)
                              : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: smartMaskProvider.isDeviceOnline
                                ? AppColors.successColor.withOpacity(0.3)
                                : Colors.orange.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.masks,
                                color: smartMaskProvider.isDeviceOnline
                                    ? AppColors.successColor
                                    : Colors.orange,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    smartMaskProvider.isDeviceOnline
                                        ? 'Smart Mask Connected & Active'
                                        : 'Smart Mask Connected but Inactive',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: smartMaskProvider.isDeviceOnline
                                          ? AppColors.successColor
                                          : Colors.orange,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    smartMaskProvider.isDeviceOnline
                                        ? 'Your mask is currently online and transmitting data.'
                                        : 'Your mask is not currently transmitting data.',
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
                      ),

                      const SizedBox(height: 12),

                      // Last updated info - only shown if we have data
                      if (smartMaskProvider.smartMaskData != null)
                        Text(
                          'Last updated: ${_formatTimeIn12Hour(smartMaskProvider.smartMaskData!.timestamp)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: AppColors.secondaryTextColor,
                          ),
                        ),
                    ],
                  ),
                )
              : const SizedBox(),

          // Sign Out Button
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(vertical: 16),
            child: CustomButton(
              text: 'Sign Out',
              onPressed: _signOut,
              isOutlined: true,
              color: AppColors.errorColor,
            ),
          ),
        ],
      ),
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

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    required Color iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
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
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: valueColor ?? AppColors.primaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color iconColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
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
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primaryTextColor,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.secondaryTextColor,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
