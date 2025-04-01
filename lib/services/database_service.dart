import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/weather_model.dart';
import '../models/breath_data_model.dart';
import '../models/user_model.dart';
import '../models/prescription_model.dart';
import '../models/medical_prescription_model.dart';
import '../constants/app_constants.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Save weather data to Firestore
  Future<void> saveWeatherData(String userId, WeatherModel weatherData) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.weatherDataCollection)
          .add(weatherData.toJson());
    } catch (e) {
      throw Exception('Error saving weather data: $e');
    }
  }

  // Get weather history for a user
  Future<List<WeatherModel>> getWeatherHistory(String userId,
      {int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.weatherDataCollection)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => WeatherModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Error getting weather history: $e');
    }
  }

  // Save breath data to Firestore
  Future<void> saveBreathData(String userId, BreathDataModel breathData) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.breathDataCollection)
          .add(breathData.toJson());
    } catch (e) {
      throw Exception('Error saving breath data: $e');
    }
  }

  // Get breath data history for a user
  Future<List<BreathDataModel>> getBreathDataHistory(String userId,
      {int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.breathDataCollection)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => BreathDataModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Error getting breath data history: $e');
    }
  }

  // Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();

      if (doc.exists) {
        return UserModel.fromJson(doc.data() as Map<String, dynamic>);
      }

      return null;
    } catch (e) {
      throw Exception('Error getting user data: $e');
    }
  }

  // Get latest weather data for a user
  Future<WeatherModel?> getLatestWeatherData(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.weatherDataCollection)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return WeatherModel.fromJson(snapshot.docs.first.data());
      }

      return null;
    } catch (e) {
      throw Exception('Error getting latest weather data: $e');
    }
  }

  // Get latest breath data for a user
  Future<BreathDataModel?> getLatestBreathData(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.breathDataCollection)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return BreathDataModel.fromJson(snapshot.docs.first.data());
      }

      return null;
    } catch (e) {
      throw Exception('Error getting latest breath data: $e');
    }
  }

  // Save environment conditions (previously prescription)
  Future<void> saveEnvironmentConditions(
      String userId, PrescriptionModel environmentData) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection('environment_conditions')
          .doc('latest')
          .set(environmentData.toJson());

      // Update user model to indicate they have environment conditions set
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({'hasEnvironmentConditions': true});
    } catch (e) {
      throw Exception('Error saving environment conditions: $e');
    }
  }

  // Get latest environment conditions
  Future<PrescriptionModel?> getLatestEnvironmentConditions(
      String userId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection('environment_conditions')
          .doc('latest')
          .get();

      if (doc.exists) {
        return PrescriptionModel.fromJson(doc.data() as Map<String, dynamic>);
      }

      return null;
    } catch (e) {
      throw Exception('Error getting environment conditions: $e');
    }
  }

  // Save medical prescription
  Future<void> saveMedicalPrescription(
      String userId, MedicalPrescriptionModel prescription) async {
    try {
      // Save prescription
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection('prescriptions')
          .doc('latest')
          .set(prescription.toJson());

      // Update user model to indicate they have a prescription
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({'hasPrescription': true});
    } catch (e) {
      throw Exception('Error saving medical prescription: $e');
    }
  }

  // Get latest medical prescription
  Future<MedicalPrescriptionModel?> getLatestMedicalPrescription(
      String userId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection('prescriptions')
          .doc('latest')
          .get();

      if (doc.exists) {
        return MedicalPrescriptionModel.fromJson(
            doc.data() as Map<String, dynamic>);
      }

      return null;
    } catch (e) {
      throw Exception('Error getting medical prescription: $e');
    }
  }

  // Get medical prescription history
  Future<List<MedicalPrescriptionModel>> getMedicalPrescriptionHistory(
      String userId) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection('prescriptions')
          .orderBy('prescribedDate', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => MedicalPrescriptionModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Error getting medical prescription history: $e');
    }
  }

  // Delete medical prescription
  Future<void> deleteMedicalPrescription(String userId) async {
    try {
      // Delete the latest prescription
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection('prescriptions')
          .doc('latest')
          .delete();

      // Update user model to indicate they no longer have a prescription
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({'hasPrescription': false});
    } catch (e) {
      throw Exception('Error deleting medical prescription: $e');
    }
  }

  // Delete environment conditions
  Future<void> deleteEnvironmentConditions(String userId) async {
    try {
      // Delete the latest environment conditions
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection('environment_conditions')
          .doc('latest')
          .delete();

      // Update user model to indicate they no longer have environment conditions
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({'hasEnvironmentConditions': false});
    } catch (e) {
      throw Exception('Error deleting environment conditions: $e');
    }
  }
}
