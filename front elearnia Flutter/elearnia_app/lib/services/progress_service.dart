import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../config/api_config.dart';

class ProgressService {
  static String get _baseUrl => ApiConfig.baseUrl;
  final http.Client _client = http.Client();
  final AuthService _authService = AuthService();

  Future<String?> _getToken() async {
    return _authService.getToken();
  }

  // Mettre à jour la progression d'un étudiant pour un cours
  Future<void> updateProgress({
    required int courseId,
    required double progress,
    bool? completed,
    double? rating,
  }) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Token manquant, merci de vous reconnecter.');
    }

    final uri = Uri.parse('$_baseUrl/student/courses/$courseId/progress');

    final body = <String, dynamic>{
      'progress': progress,
    };
    if (completed != null) {
      body['completed'] = completed;
    }
    if (rating != null) {
      body['rating'] = rating;
    }

    final response = await _client.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Erreur mise à jour progression (${response.statusCode}) : ${response.body}');
    }
  }

  // Récupérer la progression des étudiants pour un cours (côté prof)
  Future<List<StudentProgress>> getStudentsProgress(int courseId) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Token manquant, merci de vous reconnecter.');
    }

    final uri = Uri.parse('$_baseUrl/teacher/courses/$courseId/students-progress');

    final response = await _client.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Erreur récupération progression (${response.statusCode}) : ${response.body}');
    }

    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => StudentProgress.fromJson(json)).toList();
  }
}

class StudentProgress {
  final int studentId;
  final String fullName;
  final String email;
  final double progress;
  final bool completed;
  final double? rating;

  StudentProgress({
    required this.studentId,
    required this.fullName,
    required this.email,
    required this.progress,
    required this.completed,
    this.rating,
  });

  factory StudentProgress.fromJson(Map<String, dynamic> json) {
    return StudentProgress(
      studentId: (json['studentId'] as num?)?.toInt() ?? 0,
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      completed: (json['completed'] as bool?) ?? false,
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : null,
    );
  }
}

