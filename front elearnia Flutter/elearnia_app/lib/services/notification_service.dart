import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class Notification {
  final int id;
  final String message;
  final String type;
  final bool read;
  final String createdAt;

  Notification({
    required this.id,
    required this.message,
    required this.type,
    required this.read,
    required this.createdAt,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'] as int,
      message: json['message'] as String,
      type: json['type'] as String,
      read: (json['read'] as bool?) ?? false,
      createdAt: json['createdAt'] as String,
    );
  }
}

class NotificationService {
  static String get _baseUrl => ApiConfig.baseUrl;
  final AuthService _authService = AuthService();

  Future<List<Notification>> getNotifications() async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Token manquant, merci de vous reconnecter.');
    }

    final uri = Uri.parse('$_baseUrl/notifications');

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      return data
          .map((e) => Notification.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception(
          'Erreur chargement notifications (${response.statusCode}) : ${response.body}');
    }
  }

  Future<List<Notification>> getUnreadNotifications() async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Token manquant, merci de vous reconnecter.');
    }

    final uri = Uri.parse('$_baseUrl/notifications/unread');

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      return data
          .map((e) => Notification.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception(
          'Erreur chargement notifications (${response.statusCode}) : ${response.body}');
    }
  }

  Future<void> markAsRead(int notificationId) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Token manquant, merci de vous reconnecter.');
    }

    final uri = Uri.parse('$_baseUrl/notifications/$notificationId/read');

    final response = await http.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(
          'Erreur marquer notification (${response.statusCode}) : ${response.body}');
    }
  }

  Future<void> markAllAsRead() async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Token manquant, merci de vous reconnecter.');
    }

    final uri = Uri.parse('$_baseUrl/notifications/read-all');

    final response = await http.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(
          'Erreur marquer toutes notifications (${response.statusCode}) : ${response.body}');
    }
  }
}











