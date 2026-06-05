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

  static Future<String> descargarArchivo(String endpoint, String nombreArchivo) async {
    final url = '${AppConstants.apiUrl}$endpoint';
    return Uri.encodeFull('$url&_token=${AuthService.token}&_filename=$nombreArchivo');
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

