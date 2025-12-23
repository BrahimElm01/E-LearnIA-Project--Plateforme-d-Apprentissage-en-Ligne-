import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/review.dart';
import '../config/api_config.dart';
import 'auth_service.dart';

class ReviewService {
  static String get _baseUrl => ApiConfig.baseUrl;
  final http.Client _client = http.Client();
  final AuthService _authService = AuthService();

  Future<String?> _getToken() async {
    return _authService.getToken();
  }

  // Ajouter un review (étudiant)
  Future<Review> addReview({
    required int courseId,
    required int rating,
    String? comment,
  }) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Token manquant, merci de vous reconnecter.');
    }

    final uri = Uri.parse('$_baseUrl/student/courses/$courseId/reviews');
    final response = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'rating': rating,
        'comment': comment,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return Review.fromJson(data);
    } else {
      throw Exception(
          'Erreur ajout review (${response.statusCode}) : ${response.body}');
    }
  }

  // Obtenir les reviews approuvés d'un cours (étudiant)
  Future<List<Review>> getApprovedReviews(int courseId) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Token manquant, merci de vous reconnecter.');
    }

    final uri = Uri.parse('$_baseUrl/student/courses/$courseId/reviews');
    final response = await _client.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Review.fromJson(json as Map<String, dynamic>)).toList();
    } else {
      throw Exception(
          'Erreur récupération reviews (${response.statusCode}) : ${response.body}');
    }
  }

  // Obtenir tous les reviews d'un cours (professeur)
  Future<List<Review>> getCourseReviews(int courseId) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Token manquant, merci de vous reconnecter.');
    }

    final uri = Uri.parse('$_baseUrl/teacher/courses/$courseId/reviews');
    final response = await _client.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Review.fromJson(json as Map<String, dynamic>)).toList();
    } else {
      throw Exception(
          'Erreur récupération reviews (${response.statusCode}) : ${response.body}');
    }
  }

  // Approuver un review (professeur)
  Future<Review> approveReview(int reviewId) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Token manquant, merci de vous reconnecter.');
    }

    final uri = Uri.parse('$_baseUrl/teacher/courses/reviews/$reviewId/approve');
    final response = await _client.put(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return Review.fromJson(data);
    } else {
      throw Exception(
          'Erreur approbation review (${response.statusCode}) : ${response.body}');
    }
  }

  // Rejeter un review (professeur)
  Future<Review> rejectReview(int reviewId) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Token manquant, merci de vous reconnecter.');
    }

    final uri = Uri.parse('$_baseUrl/teacher/courses/reviews/$reviewId/reject');
    final response = await _client.put(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return Review.fromJson(data);
    } else {
      throw Exception(
          'Erreur rejet review (${response.statusCode}) : ${response.body}');
    }
  }
}

