import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../components/new_types.dart';

void sanitizeFileName(List<FileData> files, {int maxBytes = 1000}) {
  for (var file in files) {
    String name = file.name
        .replaceAll(' ', '_')
        .replaceAll(RegExp(r'[^\x00-\x7F]'), '_') // Remove non-ASCII
        .replaceAll(RegExp(r'[^\w\d_.-]'), '_')   // Safe ASCII chars only
        .replaceAll(RegExp(r'_+'), '_')           // Collapse underscores
        .replaceAll(RegExp(r'^_+|_+$'), '');      // Trim leading/trailing _

    final bytes = utf8.encode(name);
    if (bytes.length > maxBytes) {
      final extension = name.contains('.') ? '.${name.split('.').last}' : '';
      final hashed = sha1.convert(bytes).toString();
      name = '$hashed$extension';
    }

    file.name = name; // ✅ Mutate the object directly
  }
}
