import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

class WebFilePickerResult {
  final String name;
  final Uint8List bytes;

  WebFilePickerResult({required this.name, required this.bytes});
}

class WebFilePicker {
  static Future<WebFilePickerResult?> pickFile({
    List<String> allowedExtensions = const [],
  }) async {
    final completer = Completer<WebFilePickerResult?>();

    final input = html.FileUploadInputElement()
      ..accept = _buildAccept(allowedExtensions)
      ..style.display = 'none';

    html.document.body?.append(input);

    input.onChange.listen((e) async {
      final files = input.files;
      if (files != null && files.isNotEmpty) {
        final file = files[0];
        final reader = html.FileReader();

        reader.onLoadEnd.listen((e) {
          try {
            final bytes = reader.result as List<int>;
            completer.complete(WebFilePickerResult(
              name: file.name,
              bytes: Uint8List.fromList(bytes),
            ));
          } catch (err) {
            completer.completeError(err);
          }
        });

        reader.onError.listen((e) {
          completer.completeError(reader.error ?? Exception('FileReader error'));
        });

        reader.readAsArrayBuffer(file);
      } else {
        completer.complete(null);
      }

      input.remove();
    });

    input.onError.listen((e) {
      completer.completeError(Exception('File picker canceled'));
      input.remove();
    });

    input.click();

    return completer.future;
  }

  static String _buildAccept(List<String> extensions) {
    if (extensions.isEmpty) return '';
    return extensions.map((e) => '.$e').join(',');
  }
}
