import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'html_file_picker.dart';
import 'debug_service.dart';

class SmartFilePicker {
  static Future<({String name, dynamic bytes})?> pickFile() async {
    DebugService.log('SmartFilePicker: kIsWeb=$kIsWeb');

    try {
      if (kIsWeb) {
        DebugService.log('SmartFilePicker: Usando HtmlFilePicker');
        final result = await HtmlFilePicker.pickFile();
        if (result != null) {
          DebugService.log('SmartFilePicker: HtmlFilePicker OK - name=${result.name}, bytes=${result.bytes.length}');
          return result;
        } else {
          DebugService.log('SmartFilePicker: HtmlFilePicker retornó null');
          return null;
        }
      } else {
        DebugService.log('SmartFilePicker: Usando FilePicker');
        final result = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: false);
        if (result != null && result.files.isNotEmpty) {
          final file = result.files.first;
          DebugService.log('SmartFilePicker: FilePicker OK - name=${file.name}');
          if (file.bytes != null) {
            return (name: file.name, bytes: file.bytes);
          } else if (file.path != null) {
            final fileContent = await File(file.path!).readAsBytes();
            return (name: file.name, bytes: fileContent);
          }
        } else {
          DebugService.log('SmartFilePicker: FilePicker retornó null');
          return null;
        }
      }
    } catch (e) {
      DebugService.log('SmartFilePicker: Error - $e');
    }
    return null;
  }
}
