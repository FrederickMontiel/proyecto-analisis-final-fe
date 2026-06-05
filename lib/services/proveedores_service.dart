import 'package:http/http.dart' as http;
import 'dart:convert';
import 'auth_service.dart';
import '../config/constants.dart';

class ProveedoresService {
  static Future<List<dynamic>> obtenerProveedores() async {
    if (!AuthService.estaAutenticado) return [];

    try {
      final response = await http.get(
        Uri.parse('${AppConstants.apiUrl}/proveedores'),
        headers: {'Authorization': 'Bearer ${AuthService.token}'},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json is List) {
          return json.cast<dynamic>();
        } else if (json is Map<String, dynamic> && json['data'] is List) {
          return (json['data'] as List).cast<dynamic>();
        }
        return [];
      } else if (response.statusCode == 401) {
        await AuthService.cerrarSesion();
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}
