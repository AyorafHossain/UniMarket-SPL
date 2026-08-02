import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class CloudinaryService {
  static const String cloudName = 'dbpudqcuu';
  // Note: Unsigned uploads require an unsigned upload preset.
  // The user should make sure an unsigned preset exists with this name.
  static const String uploadPreset = 'unimarket_upload';

  /// Internal generic upload method
  Future<String> _uploadMedia({
    required File file,
    required String folder,
    required String resourceType,
  }) async {
    try {
      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/$resourceType/upload');
      final request = http.MultipartRequest('POST', uri);

      // Add the file to the request
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
        ),
      );

      // Add other required fields for unsigned upload
      request.fields['upload_preset'] = uploadPreset;
      request.fields['folder'] = folder;

      debugPrint('CloudinaryService: Sending upload request to $uri with folder: $folder');
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final String? secureUrl = responseData['secure_url'];
        if (secureUrl != null && secureUrl.isNotEmpty) {
          debugPrint('CloudinaryService: Upload successful. secure_url: $secureUrl');
          return secureUrl;
        } else {
          throw Exception('Cloudinary response did not contain secure_url');
        }
      } else {
        debugPrint('CloudinaryService: Upload failed with status: ${response.statusCode}');
        debugPrint('CloudinaryService: Error response: ${response.body}');
        
        // Try to parse the error message from response body
        String errorMessage = 'Upload failed';
        try {
          final errorData = json.decode(response.body);
          if (errorData['error'] != null && errorData['error']['message'] != null) {
            errorMessage = errorData['error']['message'];
          }
        } catch (_) {}
        
        throw Exception('Cloudinary upload failed: $errorMessage');
      }
    } catch (e) {
      debugPrint('CloudinaryService Exception: $e');
      rethrow;
    }
  }

  /// Uploads an image file to Cloudinary.
  Future<String> uploadImage({required File imageFile, required String folder}) {
    return _uploadMedia(file: imageFile, folder: folder, resourceType: 'image');
  }

  /// Uploads a video file to Cloudinary.
  Future<String> uploadVideo({required File videoFile, required String folder}) {
    return _uploadMedia(file: videoFile, folder: folder, resourceType: 'video');
  }

  /// Uploads an audio file to Cloudinary.
  Future<String> uploadAudio({required File audioFile, required String folder}) {
    return _uploadMedia(file: audioFile, folder: folder, resourceType: 'video');
  }

  /// Uploads a raw document/file to Cloudinary.
  Future<String> uploadFile({required File file, required String folder}) {
    return _uploadMedia(file: file, folder: folder, resourceType: 'raw');
  }
}
