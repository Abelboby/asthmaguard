import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../providers/smart_mask_provider.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../models/medical_prescription_model.dart';
import '../../models/user_model.dart';
import '../../widgets/breath_parameter_chart.dart';

class SmartMaskScreen extends StatefulWidget {
  const SmartMaskScreen({Key? key}) : super(key: key);

  @override
  State<SmartMaskScreen> createState() => _SmartMaskScreenState();
}

class _SmartMaskScreenState extends State<SmartMaskScreen>
    with SingleTickerProviderStateMixin {
  // Animation controller for the highlight animations
  late AnimationController _animationController;
  final DatabaseService _databaseService = DatabaseService();
  final AuthService _authService = AuthService();
  UserModel? _user;
  MedicalPrescriptionModel? _prescription;
  bool _isLoadingUser = false;
  bool _isLoadingPrescription = false;
  bool _isSavingPrescription = false;
  bool _showPrescriptionForm = false;

  // Controllers for the prescription form
  final _temperatureController = TextEditingController();
  final _humidityController = TextEditingController();
  final _inhalerMedicineController = TextEditingController();
  final _doctorNameController = TextEditingController();
  final _additionalNotesController = TextEditingController();

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
        // Reset highlights in the provider when animation completes
        Provider.of<SmartMaskProvider>(context, listen: false)
            .resetHighlights();
        _animationController.reset();
      }
    });

    // Load user data and prescription
    _loadUserData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _temperatureController.dispose();
    _humidityController.dispose();
    _inhalerMedicineController.dispose();
    _doctorNameController.dispose();
    _additionalNotesController.dispose();
    super.dispose();
  }

  // Load user data and prescription
  Future<void> _loadUserData() async {
    setState(() {
      _isLoadingUser = true;
    });

    try {
      final user = await _authService.getUserModel();
      if (user != null) {
        _user = user;

        // Load prescription if user has one
        if (_user!.hasPrescription) {
          setState(() {
            _isLoadingPrescription = true;
          });

          try {
            _prescription =
                await _databaseService.getLatestMedicalPrescription(_user!.id);

            // Populate the form if prescription exists
            if (_prescription != null) {
              _temperatureController.text =
                  _prescription!.idealTemperature.toString();
              _humidityController.text =
                  _prescription!.idealHumidity.toString();
              _inhalerMedicineController.text = _prescription!.inhalerMedicine;
              _doctorNameController.text = _prescription!.doctorName;
              _additionalNotesController.text = _prescription!.additionalNotes;
            }
          } catch (e) {
            print('Error loading prescription: $e');
          } finally {
            if (mounted) {
              setState(() {
                _isLoadingPrescription = false;
              });
            }
          }
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingUser = false;
        });
      }
    }
  }

  // Save prescription
  Future<void> _savePrescription() async {
    if (_user == null) return;

    // Validate inputs
    if (_temperatureController.text.isEmpty ||
        _humidityController.text.isEmpty ||
        _inhalerMedicineController.text.isEmpty ||
        _doctorNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() {
      _isSavingPrescription = true;
    });

    try {
      // Parse values
      final temperature = double.parse(_temperatureController.text);
      final humidity = double.parse(_humidityController.text);

      // Create prescription model
      final prescription = MedicalPrescriptionModel(
        idealTemperature: temperature,
        idealHumidity: humidity,
        inhalerMedicine: _inhalerMedicineController.text,
        doctorName: _doctorNameController.text,
        additionalNotes: _additionalNotesController.text,
        prescribedDate: DateTime.now(),
      );

      // Save to Firebase
      await _databaseService.saveMedicalPrescription(_user!.id, prescription);

      // Update local state
      setState(() {
        _prescription = prescription;
        _showPrescriptionForm = false;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prescription saved successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving prescription: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSavingPrescription = false;
        });
      }
    }
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
        child: Consumer<SmartMaskProvider>(
          builder: (context, smartMaskProvider, child) {
            // Check if highlight animation should be triggered
            if ((smartMaskProvider.showTemperatureHighlight ||
                    smartMaskProvider.showHumidityHighlight) &&
                !_animationController.isAnimating) {
              _animationController.forward();
            }

            return SingleChildScrollView(
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
                            color: !smartMaskProvider.isConnected
                                ? Colors.grey.withOpacity(0.1)
                                : smartMaskProvider.isDeviceOnline
                                    ? AppColors.successColor.withOpacity(0.1)
                                    : AppColors.errorColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: !smartMaskProvider.isConnected
                                    ? Colors.grey.withOpacity(0.2)
                                    : smartMaskProvider.isDeviceOnline
                                        ? AppColors.successColor
                                            .withOpacity(0.2)
                                        : AppColors.errorColor.withOpacity(0.2),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              Icons.masks,
                              size: 60,
                              color: !smartMaskProvider.isConnected
                                  ? Colors.grey
                                  : smartMaskProvider.isDeviceOnline
                                      ? AppColors.successColor
                                      : AppColors.errorColor,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Connection Status
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: !smartMaskProvider.isConnected
                                ? Colors.grey.withOpacity(0.1)
                                : smartMaskProvider.isDeviceOnline
                                    ? AppColors.successColor.withOpacity(0.1)
                                    : AppColors.errorColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: !smartMaskProvider.isConnected
                                  ? Colors.grey.withOpacity(0.3)
                                  : smartMaskProvider.isDeviceOnline
                                      ? AppColors.successColor.withOpacity(0.3)
                                      : AppColors.errorColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            !smartMaskProvider.isConnected
                                ? 'Not Connected'
                                : smartMaskProvider.isDeviceOnline
                                    ? 'Connected - Online'
                                    : 'Connected - Offline',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: !smartMaskProvider.isConnected
                                  ? Colors.grey
                                  : smartMaskProvider.isDeviceOnline
                                      ? AppColors.successColor
                                      : AppColors.errorColor,
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Last updated
                        if (smartMaskProvider.isConnected &&
                            smartMaskProvider.smartMaskData != null)
                          Text(
                            'Last updated: ${_formatTimeIn12Hour(smartMaskProvider.smartMaskData!.timestamp)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.secondaryTextColor,
                            ),
                          ),

                        const SizedBox(height: 20),

                        // Connect Button
                        smartMaskProvider.isConnected
                            ? CustomButton(
                                text: 'Disconnect Smart Mask',
                                onPressed: () =>
                                    smartMaskProvider.disconnectSmartMask(),
                                isLoading: smartMaskProvider.isConnecting,
                                isOutlined: true,
                                color: AppColors.errorColor,
                              )
                            : CustomButton(
                                text: 'Connect Smart Mask',
                                onPressed: () => smartMaskProvider
                                    .connectToSmartMask(context),
                                isLoading: smartMaskProvider.isConnecting,
                              ),

                        if (!smartMaskProvider.isConnected)
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
                  if (smartMaskProvider.isConnected &&
                      smartMaskProvider.smartMaskData != null)
                    _buildSmartMaskDataCard(smartMaskProvider),

                  // Historical Data Charts
                  if (smartMaskProvider.isConnected) ...[
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Breath Data Trends',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryTextColor,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.refresh,
                            color: AppColors.primaryColor,
                            size: 22,
                          ),
                          onPressed: () {
                            smartMaskProvider.fetchHistoricalData();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Refreshing historical data...'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          tooltip: 'Refresh historical data',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Temperature Chart
                    BreathParameterChart(
                      data: smartMaskProvider.historicalData,
                      title: 'Breath Temperature',
                      color: AppColors.primaryColor,
                      unit: '°C',
                      isLoading: smartMaskProvider.isLoadingHistoricalData,
                      valueSelector: (data) => data.temperature,
                    ),

                    // Humidity Chart
                    BreathParameterChart(
                      data: smartMaskProvider.historicalData,
                      title: 'Breath Humidity',
                      color: Colors.blue,
                      unit: '%',
                      isLoading: smartMaskProvider.isLoadingHistoricalData,
                      valueSelector: (data) => data.humidity,
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Prescription section - renamed from Doctor's Prescription
                  Text(
                    'Prescription',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDoctorPrescriptionCard(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSmartMaskDataCard(SmartMaskProvider provider) {
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
                          provider.smartMaskData!.getFormattedTriggerLevel())
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  provider.smartMaskData!.getFormattedTriggerLevel(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(
                        provider.smartMaskData!.getFormattedTriggerLevel()),
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
                '${provider.smartMaskData!.temperature.toStringAsFixed(1)}°C',
                Icons.thermostat_outlined,
                AppColors.primaryColor, // Teal blue
                showHighlight: provider.showTemperatureHighlight,
                previousValue: provider.previousData != null
                    ? '${provider.previousData!.temperature.toStringAsFixed(1)}°C'
                    : null,
              ),
              _buildBreathDataTile(
                'Breath Humidity',
                '${provider.smartMaskData!.humidity.toStringAsFixed(1)}%',
                Icons.water_drop_outlined,
                AppColors.primaryColor, // Teal blue
                showHighlight: provider.showHumidityHighlight,
                previousValue: provider.previousData != null
                    ? '${provider.previousData!.humidity.toStringAsFixed(1)}%'
                    : null,
              ),
              _buildBreathDataTile(
                'Status',
                provider.smartMaskData!.getFormattedTriggerLevel(),
                Icons.shield_outlined,
                _getStatusColor(
                    provider.smartMaskData!.getFormattedTriggerLevel()),
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

  // Build doctor's prescription card
  Widget _buildDoctorPrescriptionCard() {
    return Container(
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
      child: _isLoadingUser || _isLoadingPrescription
          ? const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            )
          : _showPrescriptionForm
              ? _buildPrescriptionForm()
              : _buildPrescriptionPreview(),
    );
  }

  // Build the prescription preview or "add new" button
  Widget _buildPrescriptionPreview() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: _prescription != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Medical Prescription",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryTextColor,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.edit,
                        color: AppColors.primaryColor,
                        size: 20,
                      ),
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        setState(() {
                          _showPrescriptionForm = true;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildPrescriptionDetailItem(
                  'Ideal Temperature',
                  '${_prescription!.idealTemperature}°C',
                  Icons.thermostat_outlined,
                ),
                _buildPrescriptionDetailItem(
                  'Ideal Humidity',
                  '${_prescription!.idealHumidity}%',
                  Icons.water_drop_outlined,
                ),
                _buildPrescriptionDetailItem(
                  'Inhaler Medicine',
                  _prescription!.inhalerMedicine,
                  Icons.medication_outlined,
                ),
                _buildPrescriptionDetailItem(
                  'Doctor',
                  _prescription!.doctorName,
                  Icons.person_outlined,
                ),
                if (_prescription!.additionalNotes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Additional Notes:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _prescription!.additionalNotes,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.secondaryTextColor,
                    ),
                  ),
                ],
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.medical_services_outlined,
                      color: AppColors.primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "Medical Prescription",
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
                  "Add your doctor's prescription details to get personalized health recommendations.",
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 16),
                CustomButton(
                  text: 'Add Prescription',
                  onPressed: () {
                    setState(() {
                      _showPrescriptionForm = true;
                    });
                  },
                ),
              ],
            ),
    );
  }

  // Build a single prescription detail item
  Widget _buildPrescriptionDetailItem(
      String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: AppColors.primaryColor,
              size: 16,
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
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Build the prescription form
  Widget _buildPrescriptionForm() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Medical Prescription",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryTextColor,
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.close,
                  color: AppColors.secondaryTextColor,
                  size: 20,
                ),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
                onPressed: () {
                  setState(() {
                    _showPrescriptionForm = false;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Ideal Temperature (°C)',
            hintText: 'e.g. 25',
            controller: _temperatureController,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          CustomTextField(
            label: 'Ideal Humidity (%)',
            hintText: 'e.g. 50',
            controller: _humidityController,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          CustomTextField(
            label: 'Inhaler Medicine',
            hintText: 'e.g. Salbutamol',
            controller: _inhalerMedicineController,
          ),
          const SizedBox(height: 12),
          CustomTextField(
            label: "Doctor's Name",
            hintText: 'e.g. Dr. Smith',
            controller: _doctorNameController,
          ),
          const SizedBox(height: 12),
          CustomTextField(
            label: 'Additional Notes',
            hintText: 'Enter any additional notes or instructions',
            controller: _additionalNotesController,
            minLines: 3,
            maxLines: 5,
          ),
          const SizedBox(height: 20),
          CustomButton(
            text: 'Save Prescription',
            onPressed: _savePrescription,
            isLoading: _isSavingPrescription,
          ),
        ],
      ),
    );
  }
}
