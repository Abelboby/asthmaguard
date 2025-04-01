class MedicalPrescriptionModel {
  final double idealTemperature;
  final double idealHumidity;
  final String inhalerMedicine;
  final String doctorName;
  final String additionalNotes;
  final DateTime prescribedDate;

  MedicalPrescriptionModel({
    required this.idealTemperature,
    required this.idealHumidity,
    required this.inhalerMedicine,
    required this.doctorName,
    this.additionalNotes = '',
    required this.prescribedDate,
  });

  factory MedicalPrescriptionModel.fromJson(Map<String, dynamic> json) {
    return MedicalPrescriptionModel(
      idealTemperature: (json['idealTemperature'] ?? 25.0).toDouble(),
      idealHumidity: (json['idealHumidity'] ?? 50.0).toDouble(),
      inhalerMedicine: json['inhalerMedicine'] ?? 'Not specified',
      doctorName: json['doctorName'] ?? 'Not specified',
      additionalNotes: json['additionalNotes'] ?? '',
      prescribedDate: json['prescribedDate'] != null
          ? DateTime.parse(json['prescribedDate'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idealTemperature': idealTemperature,
      'idealHumidity': idealHumidity,
      'inhalerMedicine': inhalerMedicine,
      'doctorName': doctorName,
      'additionalNotes': additionalNotes,
      'prescribedDate': prescribedDate.toIso8601String(),
    };
  }
} 