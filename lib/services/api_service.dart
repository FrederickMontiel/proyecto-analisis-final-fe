import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/constants.dart';
import 'auth_service.dart';

class ApiService {
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (AuthService.token != null) 'Authorization': 'Bearer ${AuthService.token}',
  };

  static Future<dynamic> get(String endpoint) async {
    final response = await http.get(
      Uri.parse('${AppConstants.apiUrl}$endpoint'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  static Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('${AppConstants.apiUrl}$endpoint'),
      headers: _headers,
      body: jsonEncode(data),
    );
    return _handleResponse(response);
  }

  static Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('${AppConstants.apiUrl}$endpoint'),
      headers: _headers,
      body: jsonEncode(data),
    );
    return _handleResponse(response);
  }

  static Future<dynamic> delete(String endpoint) async {
    final response = await http.delete(
      Uri.parse('${AppConstants.apiUrl}$endpoint'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  static dynamic _handleResponse(http.Response response) {
    if (response.statusCode == 401) {
      AuthService.cerrarSesion();
      throw Exception('Sesión expirada');
    }
    if (response.statusCode >= 400) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Error del servidor');
    }
    if (response.body.isEmpty) return null;
    return jsonDecode(response.body);
  }
}
// ApiService: manejo 401 auto-logout, errores del servidor
// Endpoints pagos y gastos conectados al backend NestJS
// API sectores y mantenimientos conectadas
// Integracion completa frontend Flutter con API backend NestJS
