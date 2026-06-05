import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class FileService {
  static Future<String?> uploadImage(File imageFile) async {
    if (!AuthService.estaAutenticado) return null;

    try {
      final uri = Uri.parse('${Constants.apiUrl}/upload');
      final token = AuthService.token;

      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 201 || response.statusCode == 200) {
        final json = jsonDecode(responseBody) as Map<String, dynamic>;
        return json['data']['url'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
