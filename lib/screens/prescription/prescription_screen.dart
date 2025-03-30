import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../models/prescription_model.dart';
import '../../models/user_model.dart';
import '../../models/weather_model.dart';
import '../../services/database_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class PrescriptionScreen extends StatefulWidget {
  final UserModel user;
  final WeatherModel? currentWeather;

  const PrescriptionScreen({
    Key? key,
    required this.user,
    this.currentWeather,
  }) : super(key: key);

  @override
  State<PrescriptionScreen> createState() => _PrescriptionScreenState();
}

class _PrescriptionScreenState extends State<PrescriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _databaseService = DatabaseService();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isDeleting = false;
  bool _isEditing = false;
  String _errorMessage = '';
  PrescriptionModel? _prescription;

  // Form controllers
  final _minTempController = TextEditingController();
  final _maxTempController = TextEditingController();
  final _minHumidityController = TextEditingController();
  final _maxHumidityController = TextEditingController();
  final _minPressureController = TextEditingController();
  final _maxPressureController = TextEditingController();
  final _maxWindSpeedController = TextEditingController();
  final _doctorNameController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPrescription();
  }

  @override
  void dispose() {
    _minTempController.dispose();
    _maxTempController.dispose();
    _minHumidityController.dispose();
    _maxHumidityController.dispose();
    _minPressureController.dispose();
    _maxPressureController.dispose();
    _maxWindSpeedController.dispose();
    _doctorNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadPrescription() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final prescription =
          await _databaseService.getLatestPrescription(widget.user.id);

      setState(() {
        _prescription = prescription;
        _isLoading = false;
        _isEditing = prescription != null;
      });

      if (prescription != null) {
        // Populate form fields
        _minTempController.text = prescription.minTemperature.toString();
        _maxTempController.text = prescription.maxTemperature.toString();
        _minHumidityController.text = prescription.minHumidity.toString();
        _maxHumidityController.text = prescription.maxHumidity.toString();
        _minPressureController.text = prescription.minPressure.toString();
        _maxPressureController.text = prescription.maxPressure.toString();
        _maxWindSpeedController.text = prescription.maxWindSpeed.toString();
        _doctorNameController.text = prescription.doctorName;
        _notesController.text = prescription.notes;
      } else {
        // Set default values
        _minTempController.text = '15.0';
        _maxTempController.text = '30.0';
        _minHumidityController.text = '30';
        _maxHumidityController.text = '70';
        _minPressureController.text = '990';
        _maxPressureController.text = '1030';
        _maxWindSpeedController.text = '5.0';
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading prescription: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _savePrescription() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = '';
    });

    try {
      final prescription = PrescriptionModel(
        minTemperature: double.parse(_minTempController.text),
        maxTemperature: double.parse(_maxTempController.text),
        minHumidity: int.parse(_minHumidityController.text),
        maxHumidity: int.parse(_maxHumidityController.text),
        minPressure: int.parse(_minPressureController.text),
        maxPressure: int.parse(_maxPressureController.text),
        maxWindSpeed: double.parse(_maxWindSpeedController.text),
        doctorName: _doctorNameController.text,
        notes: _notesController.text,
        prescribedDate: DateTime.now(),
      );

      await _databaseService.savePrescription(widget.user.id, prescription);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Prescription saved successfully!')));
        setState(() {
          _prescription = prescription;
          _isSaving = false;
          _isEditing = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error saving prescription: ${e.toString()}';
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _deletePrescription() async {
    // Show confirmation dialog before deleting
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Prescription?'),
        content: const Text(
            'Are you sure you want to delete this prescription? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    setState(() {
      _isDeleting = true;
      _errorMessage = '';
    });

    try {
      await _databaseService.deletePrescription(widget.user.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Prescription deleted successfully')));

        // Reset form
        _minTempController.text = '15.0';
        _maxTempController.text = '30.0';
        _minHumidityController.text = '30';
        _maxHumidityController.text = '70';
        _minPressureController.text = '990';
        _maxPressureController.text = '1030';
        _maxWindSpeedController.text = '5.0';
        _doctorNameController.text = '';
        _notesController.text = '';

        setState(() {
          _prescription = null;
          _isDeleting = false;
          _isEditing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error deleting prescription: ${e.toString()}';
          _isDeleting = false;
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
          _isEditing ? 'Edit Prescription' : 'New Prescription',
          style: TextStyle(
            color: AppColors.primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        actions: _isEditing
            ? [
                IconButton(
                  icon: Icon(Icons.delete_outline, color: AppColors.errorColor),
                  onPressed: _isDeleting ? null : _deletePrescription,
                  tooltip: 'Delete Prescription',
                ),
              ]
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? _buildErrorView()
              : _buildContent(),
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
              onPressed: _loadPrescription,
              width: 200,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Introduction Card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
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
                        'Doctor Prescribed Parameters',
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
                  'Enter the safe ranges for environmental parameters as prescribed by your doctor. The app will alert you when conditions exceed these thresholds.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.secondaryTextColor,
                  ),
                ),
                if (_prescription != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Last Updated: ${DateFormat('MMM d, yyyy').format(_prescription!.prescribedDate)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: AppColors.secondaryTextColor,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Safety Card (if current weather is available)
          if (widget.currentWeather != null && _prescription != null)
            _buildSafetyCard(),

          const SizedBox(height: 16),

          // Form
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Prescribed Parameters',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryTextColor,
                  ),
                ),
                const SizedBox(height: 16),

                // Temperature Range
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        label: 'Min Temperature (°C)',
                        hintText: '15.0',
                        controller: _minTempController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Enter valid number';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomTextField(
                        label: 'Max Temperature (°C)',
                        hintText: '30.0',
                        controller: _maxTempController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Enter valid number';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Humidity Range
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        label: 'Min Humidity (%)',
                        hintText: '30',
                        controller: _minHumidityController,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Enter valid number';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomTextField(
                        label: 'Max Humidity (%)',
                        hintText: '70',
                        controller: _maxHumidityController,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Enter valid number';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Pressure Range
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        label: 'Min Pressure (hPa)',
                        hintText: '990',
                        controller: _minPressureController,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Enter valid number';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomTextField(
                        label: 'Max Pressure (hPa)',
                        hintText: '1030',
                        controller: _maxPressureController,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Enter valid number';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Max Wind Speed
                CustomTextField(
                  label: 'Max Wind Speed (m/s)',
                  hintText: '5.0',
                  controller: _maxWindSpeedController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Required';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Enter valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Doctor Name
                CustomTextField(
                  label: 'Doctor Name',
                  hintText: 'Dr. Smith',
                  controller: _doctorNameController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter doctor name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Notes
                CustomTextField(
                  label: 'Additional Notes',
                  hintText: 'Any special instructions from your doctor...',
                  controller: _notesController,
                  maxLines: 3,
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    if (_isEditing) ...[
                      Expanded(
                        child: CustomButton(
                          text: 'Delete',
                          onPressed: _deletePrescription,
                          isLoading: _isDeleting,
                          color: AppColors.errorColor,
                          isOutlined: true,
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    Expanded(
                      child: CustomButton(
                        text: _isEditing ? 'Update' : 'Save',
                        onPressed: _savePrescription,
                        isLoading: _isSaving,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyCard() {
    final weather = widget.currentWeather!;
    final prescription = _prescription!;

    final safetyCheck = prescription.isSafeWeather(weather.temperature,
        weather.humidity, weather.pressure, weather.windSpeed);

    final isOverallSafe = prescription.isOverallSafe(weather.temperature,
        weather.humidity, weather.pressure, weather.windSpeed);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
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
                  color: isOverallSafe
                      ? AppColors.successColor.withOpacity(0.1)
                      : AppColors.errorColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isOverallSafe
                      ? Icons.check_circle_outline
                      : Icons.warning_amber_rounded,
                  color: isOverallSafe
                      ? AppColors.successColor
                      : AppColors.errorColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isOverallSafe
                      ? 'Current Conditions Are Safe'
                      : 'Warning: Unsafe Conditions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isOverallSafe
                        ? AppColors.successColor
                        : AppColors.errorColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Parameter Checks
          _buildParameterStatusTile(
            'Temperature',
            '${weather.temperature.toStringAsFixed(1)}°C',
            '${prescription.minTemperature.toStringAsFixed(1)} - ${prescription.maxTemperature.toStringAsFixed(1)}°C',
            safetyCheck['temperature'] ?? false,
          ),

          _buildParameterStatusTile(
            'Humidity',
            '${weather.humidity}%',
            '${prescription.minHumidity} - ${prescription.maxHumidity}%',
            safetyCheck['humidity'] ?? false,
          ),

          _buildParameterStatusTile(
            'Pressure',
            '${weather.pressure} hPa',
            '${prescription.minPressure} - ${prescription.maxPressure} hPa',
            safetyCheck['pressure'] ?? false,
          ),

          _buildParameterStatusTile(
            'Wind Speed',
            '${weather.windSpeed} m/s',
            'Max ${prescription.maxWindSpeed} m/s',
            safetyCheck['windSpeed'] ?? false,
          ),
        ],
      ),
    );
  }

  Widget _buildParameterStatusTile(
      String parameter, String currentValue, String safeRange, bool isSafe) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(
            isSafe ? Icons.check_circle : Icons.cancel,
            color: isSafe ? AppColors.successColor : AppColors.errorColor,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              parameter,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.primaryTextColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              currentValue,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color:
                    isSafe ? AppColors.primaryTextColor : AppColors.errorColor,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'Safe: $safeRange',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.secondaryTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
