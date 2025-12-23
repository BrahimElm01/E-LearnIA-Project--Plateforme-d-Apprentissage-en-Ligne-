import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'dart:convert';
import '../config/api_config.dart';
import 'auth_service.dart';

class FileUploadService {
  static String get _baseUrl => ApiConfig.baseUrl;
  final AuthService _authService = AuthService();

  Future<String?> uploadImage(File imageFile) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Token manquant, merci de vous reconnecter.');
    }

    final uri = Uri.parse('$_baseUrl/api/files/upload-image');

    // Créer la requête multipart
    var request = http.MultipartRequest('POST', uri);
    
    // Ajouter le header Authorization
    request.headers['Authorization'] = 'Bearer $token';

    // Ajouter le fichier avec le Content-Type approprié
    var fileStream = http.ByteStream(imageFile.openRead());
    var fileLength = await imageFile.length();
    var filename = imageFile.path.split('/').last;
    
    // Détecter le type MIME basé sur l'extension
    String? mimeType = lookupMimeType(imageFile.path);
    if (mimeType == null || !mimeType.startsWith('image/')) {
      // Par défaut, utiliser image/jpeg si le type n'est pas détecté
      mimeType = 'image/jpeg';
    }
    
    var multipartFile = http.MultipartFile(
      'file',
      fileStream,
      fileLength,
      filename: filename,
      contentType: http.MediaType.parse(mimeType),
    );
    request.files.add(multipartFile);

    // Envoyer la requête
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['url'] as String?;
    } else {
      throw Exception(
          'Erreur upload image (${response.statusCode}) : ${response.body}');
    }
  }

  Future<String?> uploadVideo(File videoFile) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Token manquant, merci de vous reconnecter.');
    }

    final uri = Uri.parse('$_baseUrl/api/files/upload-video');

    // Créer la requête multipart
    var request = http.MultipartRequest('POST', uri);
    
    // Ajouter le header Authorization
    request.headers['Authorization'] = 'Bearer $token';

    // Ajouter le fichier avec le Content-Type approprié
    var fileStream = http.ByteStream(videoFile.openRead());
    var fileLength = await videoFile.length();
    var filename = videoFile.path.split('/').last;
    
    // Détecter le type MIME basé sur l'extension
    String? mimeType = lookupMimeType(videoFile.path);
    if (mimeType == null || !mimeType.startsWith('video/')) {
      // Par défaut, utiliser video/mp4 si le type n'est pas détecté
      mimeType = 'video/mp4';
    }
    
    var multipartFile = http.MultipartFile(
      'file',
      fileStream,
      fileLength,
      filename: filename,
      contentType: http.MediaType.parse(mimeType),
    );
    request.files.add(multipartFile);

    // Envoyer la requête
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['url'] as String?;
    } else {
      throw Exception(
          'Erreur upload vidéo (${response.statusCode}) : ${response.body}');
    }
  }
}

