class UserModel {
  final String id;
  final String email;
  final String name;
  final String? location;
  final String? profileImage;
  final bool hasSmartMask;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.location,
    this.profileImage,
    this.hasSmartMask = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      location: json['location'],
      profileImage: json['profileImage'],
      hasSmartMask: json['hasSmartMask'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'location': location,
      'profileImage': profileImage,
      'hasSmartMask': hasSmartMask,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? location,
    String? profileImage,
    bool? hasSmartMask,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      location: location ?? this.location,
      profileImage: profileImage ?? this.profileImage,
      hasSmartMask: hasSmartMask ?? this.hasSmartMask,
    );
  }
}
