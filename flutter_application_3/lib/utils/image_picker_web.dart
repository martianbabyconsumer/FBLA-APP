import 'dart:async';
import 'dart:html' as html;

/// Returns a base64 data URL (e.g. "data:image/png;base64,...") or null if cancelled.
Future<String?> pickImageWeb() async {
  final input = html.FileUploadInputElement();
  input.accept = 'image/*';
  input.multiple = false;
  final completer = Completer<String?>();
  input.onChange.listen((_) {
    final files = input.files;
    if (files == null || files.isEmpty) {
      completer.complete(null);
      return;
    }
    final file = files.first;
    final reader = html.FileReader();
    reader.readAsDataUrl(file);
    reader.onLoad.listen((_) {
      completer.complete(reader.result as String?);
    });
    reader.onError.listen((_) => completer.complete(null));
  });
  input.click();
  return completer.future;
}
