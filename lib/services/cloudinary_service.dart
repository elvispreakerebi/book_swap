import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CloudinaryService {
  final String cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
  final String apiKey = dotenv.env['CLOUDINARY_API_KEY'] ?? '';
  final String apiSecret = dotenv.env['CLOUDINARY_API_SECRET'] ?? '';

  // Upload image file
  Future<String?> uploadImage(File file, {String? folder}) async {
    final url = 'https://api.cloudinary.com/v1_1/$cloudName/image/upload';

    final request = http.MultipartRequest('POST', Uri.parse(url))
      ..fields['upload_preset'] = dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? '';
    if (folder != null) {
      request.fields['folder'] = folder;
    }
    request.files.add(await http.MultipartFile.fromPath('file', file.path));
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      return data['secure_url'] as String?;
    }
    return null;
  }

  // Delete an image with its public ID
  Future<bool> deleteImage(String publicId) async {
    final String auth = base64Encode(utf8.encode('$apiKey:$apiSecret'));
    final url = 'https://api.cloudinary.com/v1_1/$cloudName/image/destroy';
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Basic $auth',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'public_id': publicId}),
    );
    return response.statusCode == 200;
  }

  // This just returns direct url string, so technically 'get' is just using the url.
  String getImageUrl(String publicId) {
    return 'https://res.cloudinary.com/$cloudName/image/upload/$publicId.jpg';
  }
}
