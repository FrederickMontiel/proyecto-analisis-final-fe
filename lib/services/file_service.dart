import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../config/constants.dart';

class FileService {
  static String _getContentType(String fileName) {
    if (fileName.endsWith('.png')) return 'image/png';
    if (fileName.endsWith('.jpg') || fileName.endsWith('.jpeg')) return 'image/jpeg';
    if (fileName.endsWith('.webp')) return 'image/webp';
    return 'image/png';
  }

  static Future<String?> uploadImage(dynamic imageFile, {String? fileName}) async {
    if (!AuthService.estaAutenticado) return null;

    try {
      final uri = Uri.parse('${AppConstants.apiUrl}/upload');
      final token = AuthService.token;
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token';

      if (imageFile is File) {
        final path = imageFile.path;
        final name = path.split('/').last;
        final contentType = _getContentType(name);
        request.files.add(await http.MultipartFile.fromPath('file', path, contentType: http.MediaType.parse(contentType)));
      } else if (imageFile is Uint8List) {
        final name = fileName ?? 'image.png';
        final contentType = _getContentType(name);
        request.files.add(http.MultipartFile.fromBytes('file', imageFile, filename: name, contentType: http.MediaType.parse(contentType)));
      } else if (imageFile is Stream<List<int>>) {
        final name = fileName ?? 'image.png';
        final contentType = _getContentType(name);
        final bytesBuilder = BytesBuilder();
        await for (final chunk in imageFile) {
          bytesBuilder.add(chunk);
        }
        final bytes = bytesBuilder.toBytes();
        request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: name, contentType: http.MediaType.parse(contentType)));
      } else {
        return null;
      }

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
