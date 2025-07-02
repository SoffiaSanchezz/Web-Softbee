import 'package:intl/intl.dart';

DateTime _parseDate(String? dateString) {
  if (dateString == null) {
    return DateTime.now();
  }
  try {
    // First, try the standard ISO 8601 format
    return DateTime.parse(dateString);
  } catch (e) {
    // If that fails, try the RFC 1123 format
    try {
      return DateFormat("EEE, dd MMM yyyy HH:mm:ss 'GMT'").parse(dateString, true).toUtc();
    } catch (e2) {
      // If both fail, return the current time as a fallback
      print('Could not parse date: $dateString. Error: $e2');
      return DateTime.now();
    }
  }
}

class UserProfile {
  final int id;
  final String name;
  final String username;
  final String email;
  final String phone;
  final String role;
  final bool isVerified;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Apiary> apiaries;
  final String profilePicture;

  UserProfile({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.phone,
    required this.role,
    required this.isVerified,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    required this.apiaries,
    required this.profilePicture,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as int? ?? 0,
      name: json['nombre']?.toString() ?? json['name']?.toString() ?? 'Sin nombre',
      username: json['username']?.toString() ?? 'Sin usuario',
      email: json['email']?.toString() ?? 'Sin email',
      phone: json['phone']?.toString() ?? 'Sin teléfono',
      role: json['role']?.toString() ?? 'user',
      isVerified: json['isVerified'] as bool? ?? json['verified'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? json['active'] as bool? ?? true,
      createdAt: _parseDate(json['created_at']?.toString()),
      updatedAt: _parseDate(json['updated_at']?.toString() ?? json['created_at']?.toString()),
      apiaries: (json['apiaries'] as List? ?? [])
          .map((apiary) => Apiary.fromJson(apiary as Map<String, dynamic>))
          .toList(),
      profilePicture:
          json['profile_picture']?.toString() ??
          json['profilePicture']?.toString() ??
          'default_profile.jpg',
    );
  }

  String get profilePictureUrl {
    if (profilePicture == 'default_profile.jpg' || profilePicture.isEmpty) {
      return 'images/userSoftbee.png';
    }
    return 'https://softbee-back-end.onrender.com/static/profile_pictures/$profilePicture';
  }
}

class Apiary {
  final int id;
  final String name;
  final String address;
  final int hiveCount;
  final bool appliesTreatments;
  final DateTime createdAt;

  Apiary({
    required this.id,
    required this.name,
    required this.address,
    required this.hiveCount,
    required this.appliesTreatments,
    required this.createdAt,
  });

  factory Apiary.fromJson(Map<String, dynamic> json) {
    return Apiary(
      id: json['id'] as int? ?? 0,
      name: json['nombre']?.toString() ?? json['name']?.toString() ?? 'Sin nombre',
      address:
          json['direccion']?.toString() ??
          json['address']?.toString() ??
          json['location']?.toString() ??
          'Sin dirección',
      hiveCount: json['cantidad_colmenas'] as int? ?? json['hive_count'] as int? ?? 0,
      appliesTreatments:
          json['aplica_tratamientos'] as bool? ?? json['applies_treatments'] as bool? ?? false,
      createdAt: _parseDate(json['fecha_creacion']?.toString() ?? json['created_at']?.toString()),
    );
  }
}
