import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class ChatBotService {
  static String get _baseUrl => ApiConfig.baseUrl;
  final http.Client _client = http.Client();
  final AuthService _authService = AuthService();

  Future<String?> _getToken() async {
    return _authService.getToken();
  }

  Future<String> sendMessage(String message) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Token manquant, merci de vous reconnecter.');
    }

    final uri = Uri.parse('$_baseUrl/student/chatbot/message');

    final response = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'message': message,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['response'] as String;
    } else {
      throw Exception(
          'Erreur chatbot (${response.statusCode}) : ${response.body}');
    }
  }
}










