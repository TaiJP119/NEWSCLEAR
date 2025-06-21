import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // ← add
import 'package:path/path.dart' as p; // ← add

class BackendService {
  static const _base = 'http://10.103.240.19:8000';

  /* ----------------------- text + optional image ------------------------ */
  static Future<Map<String, dynamic>> predictMultimodal({
    String? text,
    File? imageFile,
  }) async {
    final uri = Uri.parse('$_base/predict/multimodal');
    final req = http.MultipartRequest('POST', uri);

    // add plain-text field
    if (text != null) req.fields['text'] = text;

    // add image part (*** FIX #1 ***)
    if (imageFile != null) {
      req.files.add(
        await http.MultipartFile.fromPath(
          'image', // ← field name must match FastAPI param
          imageFile.path,
          contentType: _guessMimeType(imageFile.path), // optional but nice
        ),
      );
    }

    final res = await req.send();
    final body = await res.stream.bytesToString();
    if (res.statusCode != 200) throw HttpException(body);
    return jsonDecode(body);
  }

  /* helper: rough MIME guess from file extension */
  static MediaType _guessMimeType(String path) {
    final ext = p.extension(path).toLowerCase();
    switch (ext) {
      case '.png':
        return MediaType('image', 'png');
      case '.webp':
        return MediaType('image', 'webp');
      default:
        return MediaType('image', 'jpeg');
    }
  }
}
