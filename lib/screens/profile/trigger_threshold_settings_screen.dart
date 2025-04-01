import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_colors.dart';
import '../../models/smart_mask_data_model.dart';
import '../../widgets/custom_button.dart';
import '../../services/settings_service.dart';

class TriggerThresholdSettingsScreen extends StatefulWidget {
  const TriggerThresholdSettingsScreen({Key? key}) : super(key: key);

  @override
  State<TriggerThresholdSettingsScreen> createState() =>
      _TriggerThresholdSettingsScreenState();
}

class _TriggerThresholdSettingsScreenState
    extends State<TriggerThresholdSettingsScreen> {
  // Controllers for the threshold input fields
  final _highTempController = TextEditingController();
  final _lowTempController = TextEditingController();
  final _highHumidityController = TextEditingController();
  final _lowHumidityController = TextEditingController();

  // Service for managing settings
  final _settingsService = SettingsService();

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentThresholds();
  }

  @override
  void dispose() {
    _highTempController.dispose();
    _lowTempController.dispose();
    _highHumidityController.dispose();
    _lowHumidityController.dispose();
    super.dispose();
  }

  // Load current thresholds from static values and settings service
  Future<void> _loadCurrentThresholds() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Start with default values from model
      double highTemp = SmartMaskDataModel.highTempThreshold;
      double lowTemp = SmartMaskDataModel.lowTempThreshold;
      double highHumidity = SmartMaskDataModel.highHumidityThreshold;
      double lowHumidity = SmartMaskDataModel.lowHumidityThreshold;
      
      // Try to load from settings service
      final storedHighTemp = await _settingsService.getDouble('high_temp_threshold');
      final storedLowTemp = await _settingsService.getDouble('low_temp_threshold');
      final storedHighHumidity = await _settingsService.getDouble('high_humidity_threshold');
      final storedLowHumidity = await _settingsService.getDouble('low_humidity_threshold');
      
      // Update values if they exist in settings
      if (storedHighTemp != null) highTemp = storedHighTemp;
      if (storedLowTemp != null) lowTemp = storedLowTemp;
      if (storedHighHumidity != null) highHumidity = storedHighHumidity;
      if (storedLowHumidity != null) lowHumidity = storedLowHumidity;
      
      // Update the text controllers
      _highTempController.text = highTemp.toString();
      _lowTempController.text = lowTemp.toString();
      _highHumidityController.text = highHumidity.toString();
      _lowHumidityController.text = lowHumidity.toString();
    } catch (e) {
      print('Error loading thresholds: $e');
      
      // Use default values if there's an error
      _highTempController.text = SmartMaskDataModel.highTempThreshold.toString();
      _lowTempController.text = SmartMaskDataModel.lowTempThreshold.toString();
      _highHumidityController.text = SmartMaskDataModel.highHumidityThreshold.toString();
      _lowHumidityController.text = SmartMaskDataModel.lowHumidityThreshold.toString();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Save thresholds using settings service and update the model
  Future<void> _saveThresholds() async {
    setState(() {
      _isSaving = true;
    });

    try {
      // Parse values from controllers
      final highTemp = double.parse(_highTempController.text);
      final lowTemp = double.parse(_lowTempController.text);
      final highHumidity = double.parse(_highHumidityController.text);
      final lowHumidity = double.parse(_lowHumidityController.text);
      
      // Validate values
      if (highTemp <= lowTemp) {
        _showErrorSnackBar('High temperature must be greater than low temperature.');
        return;
      }
      
      if (highHumidity <= lowHumidity) {
        _showErrorSnackBar('High humidity must be greater than low humidity.');
        return;
      }
      
      // Save settings using our service (handles Firebase and SharedPreferences)
      final saveResult = await _settingsService.saveDoubleValues({
        'high_temp_threshold': highTemp,
        'low_temp_threshold': lowTemp,
        'high_humidity_threshold': highHumidity,
        'low_humidity_threshold': lowHumidity,
      });
      
      // Update the model's static thresholds
      SmartMaskDataModel.updateThresholds(
        highTemp: highTemp,
        lowTemp: lowTemp,
        highHumidity: highHumidity,
        lowHumidity: lowHumidity,
      );
      
      // Show success message with sync status
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            saveResult 
              ? 'Trigger thresholds saved and synced to cloud.' 
              : 'Trigger thresholds saved locally. Cloud sync unavailable.',
          ),
          backgroundColor: saveResult ? Colors.green : Colors.orange,
        ),
      );
      
      // Return to previous screen
      Navigator.pop(context);
    } catch (e) {
      _showErrorSnackBar('Error saving thresholds: $e');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }
  
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _resetToDefaults() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to Defaults'),
        content: const Text('Are you sure you want to reset all thresholds to default values?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _highTempController.text = '34.5';
              _lowTempController.text = '34.0';
              _highHumidityController.text = '90.0';
              _lowHumidityController.text = '80.0';
              Navigator.pop(context);
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Trigger Threshold Settings',
          style: TextStyle(
            color: AppColors.primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
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
        actions: [
          IconButton(
            icon: Icon(
              Icons.restore,
              color: AppColors.primaryColor,
            ),
            onPressed: _resetToDefaults,
            tooltip: 'Reset to defaults',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoCard(),
                    const SizedBox(height: 24),
                    _buildThresholdSettings(),
                    const SizedBox(height: 24),
                    _buildTriggerTable(),
                    const SizedBox(height: 24),
                    CustomButton(
                      text: 'Save & Sync Thresholds',
                      onPressed: _saveThresholds,
                      isLoading: _isSaving,
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Settings will sync across all your devices',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.secondaryTextColor,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.primaryColor, size: 24),
              const SizedBox(width: 12),
              const Text(
                'About Trigger Thresholds',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Customize the temperature and humidity thresholds that determine your asthma trigger risk levels. '
            'These settings affect how the app calculates and displays your risk status based on your smart mask readings.',
            style: TextStyle(
              fontSize: 15,
              color: AppColors.secondaryTextColor,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThresholdSettings() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Temperature Thresholds',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _lowTempController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Low Threshold (°C)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    helperText: 'e.g., 34.0',
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _highTempController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'High Threshold (°C)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    helperText: 'e.g., 34.5',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Humidity Thresholds',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _lowHumidityController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Low Threshold (%)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    helperText: 'e.g., 80.0',
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _highHumidityController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'High Threshold (%)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    helperText: 'e.g., 90.0',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTriggerTable() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trigger Risk Levels',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Table(
            border: TableBorder.all(
              color: Colors.grey.shade200,
              width: 1,
            ),
            columnWidths: const {
              0: FlexColumnWidth(1.2),
              1: FlexColumnWidth(1.8),
              2: FlexColumnWidth(1.8),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                ),
                children: const [
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Risk Level',
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Temperature',
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Humidity',
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
              TableRow(
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                ),
                children: [
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'High Risk',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      '> ${_highTempController.text}°C',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      '> ${_highHumidityController.text}%',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
              TableRow(
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                ),
                children: [
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Medium Risk',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      '${_lowTempController.text}°C to ${_highTempController.text}°C',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      '${_lowHumidityController.text}% to ${_highHumidityController.text}%',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
              TableRow(
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                ),
                children: [
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Low Risk',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      '< ${_lowTempController.text}°C',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      '< ${_lowHumidityController.text}%',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
} 