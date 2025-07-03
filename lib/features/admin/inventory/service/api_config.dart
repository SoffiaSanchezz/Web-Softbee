import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiConfig {
  static const String baseUrl =
      'https://softbee-back-end.onrender.com/api';

  static const int defaultApiaryId = 1;

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  /// Headers dinámicos que incluyen el token
  static Future<Map<String, String>> getHeaders() async {
    final token = await _storage.read(key: 'auth_token');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
}
