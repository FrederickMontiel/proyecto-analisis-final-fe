import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

class HtmlFilePicker {
  static Future<({String name, Uint8List bytes})?> pickFile() async {
    try {
      final completer = Completer<({String name, Uint8List bytes})?>();

      final input = html.FileUploadInputElement();
      input.accept = 'image/*';
      input.style.display = 'none';

      input.onChange.listen((e) async {
        try {
          final files = input.files;
          if (files == null || files.isEmpty) {
            completer.complete(null);
            return;
          }

          final file = files[0];
          final reader = html.FileReader();

          reader.onLoadEnd.listen((_) {
            try {
              final result = reader.result as Uint8List;
              completer.complete((name: file.name, bytes: result));
            } catch (err) {
              completer.complete(null);
            }
          });

          reader.onError.listen((_) {
            completer.complete(null);
          });

          reader.readAsArrayBuffer(file);
        } catch (err) {
          completer.complete(null);
        }
      });

      html.document.body?.append(input);
      input.click();
      input.remove();

      return await completer.future;
    } catch (e) {
      if (kDebugMode) print('HtmlFilePicker error: $e');
      return null;
    }
  }
}
