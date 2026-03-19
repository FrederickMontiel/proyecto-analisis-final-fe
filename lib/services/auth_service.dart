import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';
import '../models/usuario.dart';

class AuthService {
  static String? _token;
  static Usuario? _usuario;

  static String? get token => _token;
  static Usuario? get usuario => _usuario;
  static bool get estaAutenticado => _token != null;

  static Future<void> cargarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(AppConstants.tokenKey);
    final usuarioJson = prefs.getString(AppConstants.usuarioKey);
    if (usuarioJson != null) {
      _usuario = Usuario.fromJson(jsonDecode(usuarioJson));
    }
  }

  static Future<Usuario> login(String correo, String contrasena) async {
    final response = await http.post(
      Uri.parse('${AppConstants.apiUrl}/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'correo': correo, 'contrasena': contrasena}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Credenciales incorrectas');
    }

    final data = jsonDecode(response.body);
    _token = data['access_token'];
    _usuario = Usuario.fromJson(data['usuario']);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.tokenKey, _token!);
    await prefs.setString(AppConstants.usuarioKey, jsonEncode(_usuario!.toJson()));

    return _usuario!;
  }

  static Future<void> cerrarSesion() async {
    _token = null;
    _usuario = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.usuarioKey);
  }
}
