import 'dart:convert';
import 'package:http/http.dart' as http;

import 'auth_service.dart';
import '../config/api_config.dart';
import '../models/student_course.dart';
import '../models/lesson.dart';
import '../models/course_analytics.dart';
import '../models/quiz.dart';
import '../models/generated_course.dart';

/// Modèle pour les cours créés par le prof
class TeacherCourse {
  final int id;
  final String title;
  final String description;
  final bool published;
  final String? imageUrl;

  TeacherCourse({
    required this.id,
    required this.title,
    required this.description,
    required this.published,
    required this.imageUrl,
  });

  factory TeacherCourse.fromJson(Map<String, dynamic> json) {
    return TeacherCourse(
      id: json['id'] as int,
      title: (json['title'] ?? '') as String,
      description: (json['description'] ?? '') as String,
      published: (json['published'] as bool?) ?? false,
      imageUrl: json['imageUrl'] as String?,
    );
  }
}

class CourseService {
  CourseService();

  // Utilise la configuration partagée
  static String get _baseUrl => ApiConfig.baseUrl;

  final http.Client _client = http.Client();
  final AuthService _authService = AuthService();

  Future<String?> _getToken() async {
    return _authService.getToken();
  }

  // =================== ÉTUDIANT ===================

  Future<void> enrollToCourse(int courseId) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Token manquant, merci de vous reconnecter.');
    }

    final uri = Uri.parse('$_baseUrl/student/courses/$courseId/enroll');

    final response = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
          'Erreur inscription au cours (${response.statusCode}) : ${response.body}');
    }
  }

  Future<List<StudentCourse>> getStudentCourses() async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Token manquant, merci de vous reconnecter.');
    }

    final uri = Uri.parse('$_baseUrl/student/courses');

    final response = await _client.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      return data
          .map((e) => StudentCourse.fromJson(e as Map<String, dynamic>))
          .toList();
    } else if (response.statusCode == 403) {
      throw Exception('Erreur chargement cours étudiant (403)');
    } else {
      throw Exception(
          'Erreur chargement cours étudiant (${response.statusCode})');
    }
  }

  // =================== PROF ===================

  Future<List<TeacherCourse>> getMyTeacherCourses() async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Token manquant, merci de vous reconnecter.');
    }

    final uri = Uri.parse('$_baseUrl/teacher/courses/my');

    final response = await _client.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      return data
          .map((e) => TeacherCourse.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception(
          'Erreur chargement cours enseignant (${response.statusCode})');
    }
  }

  Future<void> createCourse({
    required String title,
    required String description,
    String? imageUrl,
  }) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Token manquant, merci de vous reconnecter.');
    }

    final uri = Uri.parse('$_baseUrl/teacher/courses');

    final response = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'title': title,
        'description': description,
        if (imageUrl != null && imageUrl.isNotEmpty) 'imageUrl': imageUrl,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
          'Erreur création cours (${response.statusCode}) : ${response.body}');
    }
  }

  Future<void> updateCourse({
    required int courseId,
    String? title,
    String? description,
    String? imageUrl,
    bool? published,
  }) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Token manquant, merci de vous reconnecter.');
    }

    final uri = Uri.parse('$_baseUrl/teacher/courses/$courseId');

    final Map<String, dynamic> body = {};
    if (title != null && title.isNotEmpty) body['title'] = title;
    if (description != null && description.isNotEmpty) body['description'] = description;
    if (imageUrl != null) body['imageUrl'] = imageUrl.isEmpty ? null : imageUrl;
    if (published != null) body['published'] = published;

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
          'Erreur modification cours (${response.statusCode}) : ${response.body}');
    }
  }

  Future<void> deleteCourse(int courseId) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Token manquant, merci de vous reconnecter.');
    }

    final uri = Uri.parse('$_baseUrl/teacher/courses/$courseId');

    final response = await _client.delete(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(
          'Erreur suppression cours (${response.statusCode}) : ${response.body}');
    }
  }

  // =================== ANALYTICS ===================

  Future<CourseAnalytics> getAnalytics() async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Token manquant, merci de vous reconnecter.');
    }

    final uri = Uri.parse('$_baseUrl/teacher/courses/analytics');

    final response = await _client.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return CourseAnalytics.fromJson(data);
    } else {
      throw Exception(
          'Erreur chargement analytics (${response.statusCode}) : ${response.body}');
    }
  }

  // =================== GÉNÉRATION DE COURS AVEC IA ===================

  Future<GeneratedCourse> generateCourseWithAI({
    required String idea,
    String? level,
  }) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Token manquant, merci de vous reconnecter.');
    }

    final uri = Uri.parse('$_baseUrl/teacher/courses/generate');

    final body = <String, dynamic>{
      'idea': idea,
    };
    if (level != null && level.isNotEmpty) {
      body['level'] = level;
    }

    final response = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return GeneratedCourse.fromJson(data);
    } else {
      throw Exception(
          'Erreur génération cours (${response.statusCode}) : ${response.body}');
    }
  }

  Future<TeacherCourse> generateAndCreateCourse({
    required String idea,
    String? level,
  }) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Token manquant, merci de vous reconnecter.');
    }

    final uri = Uri.parse('$_baseUrl/teacher/courses/generate-and-create');

    final body = <String, dynamic>{
      'idea': idea,
    };
    if (level != null && level.isNotEmpty) {
      body['level'] = level;
    }

    final response = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return TeacherCourse.fromJson(data);
    } else {
      throw Exception(
          'Erreur création cours généré (${response.statusCode}) : ${response.body}');
    }
  }

  // =================== LEÇONS (PROF) ===================

  Future<List<Lesson>> getCourseLessons(int courseId) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Token manquant, merci de vous reconnecter.');
    }

    final uri = Uri.parse('$_baseUrl/teacher/courses/$courseId/lessons');

    final response = await _client.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      return data
          .map((e) => Lesson.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception(
          'Erreur chargement leçons (${response.statusCode}) : ${response.body}');
    }
  }

  Future<Lesson> createLesson({
    required int courseId,
    required String title,
    String? description,
    required String videoUrl,
    int? duration,
    required int orderIndex,
  }) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Token manquant, merci de vous reconnecter.');
    }

    final uri = Uri.parse('$_baseUrl/teacher/courses/$courseId/lessons');

    final response = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'title': title,
        'description': description,
        'videoUrl': videoUrl,
        'duration': duration,
        'orderIndex': orderIndex,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return Lesson.fromJson(data);
    } else {
      throw Exception(
          'Erreur création leçon (${response.statusCode}) : ${response.body}');
    }
  }

  Future<void> deleteLesson(int courseId, int lessonId) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Token manquant, merci de vous reconnecter.');
    }

    final uri = Uri.parse('$_baseUrl/teacher/courses/$courseId/lessons/$lessonId');

    final response = await _client.delete(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(
          'Erreur suppression leçon (${response.statusCode}) : ${response.body}');
    }
  }

  // =================== LEÇONS (ÉTUDIANT) ===================

  Future<List<Lesson>> getStudentCourseLessons(int courseId) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Token manquant, merci de vous reconnecter.');
    }

    final uri = Uri.parse('$_baseUrl/student/courses/$courseId/lessons');

    final response = await _client.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      return data
          .map((e) => Lesson.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception(
          'Erreur chargement leçons (${response.statusCode}) : ${response.body}');
    }
  }

  // =================== QUIZ (PROFESSEUR) ===================

  Future<Quiz> createQuiz({
    required int courseId,
    required String title,
    String? description,
    int? passingScore,
    int? maxAttempts,
    required List<Map<String, dynamic>> questions,
  }) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Token manquant, merci de vous reconnecter.');
    }

    final uri = Uri.parse('$_baseUrl/teacher/courses/$courseId/quiz');

    final body = <String, dynamic>{
      'title': title,
      'questions': questions,
    };

    if (description != null) body['description'] = description;
    if (passingScore != null) body['passingScore'] = passingScore;
    if (maxAttempts != null) body['maxAttempts'] = maxAttempts;

    final response = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return Quiz.fromJson(data);
    } else {
      throw Exception(
          'Erreur création quiz (${response.statusCode}) : ${response.body}');
    }
  }

  Future<Quiz?> getQuiz(int courseId) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Token manquant, merci de vous reconnecter.');
    }

    final uri = Uri.parse('$_baseUrl/teacher/courses/$courseId/quiz');

    final response = await _client.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return Quiz.fromJson(data);
    } else if (response.statusCode == 404) {
      return null; // Pas de quiz
    } else {
      throw Exception(
          'Erreur récupération quiz (${response.statusCode}) : ${response.body}');
    }
  }

  Future<Quiz> updateQuiz({
    required int courseId,
    String? title,
    String? description,
    int? passingScore,
    int? maxAttempts,
    List<Map<String, dynamic>>? questions,
  }) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Token manquant, merci de vous reconnecter.');
    }

    final uri = Uri.parse('$_baseUrl/teacher/courses/$courseId/quiz');

    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (description != null) body['description'] = description;
    if (passingScore != null) body['passingScore'] = passingScore;
    if (maxAttempts != null) body['maxAttempts'] = maxAttempts;
    if (questions != null) body['questions'] = questions;

    final response = await _client.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return Quiz.fromJson(data);
    } else {
      throw Exception(
          'Erreur modification quiz (${response.statusCode}) : ${response.body}');
    }
  }

  Future<void> deleteQuiz(int courseId) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Token manquant, merci de vous reconnecter.');
    }

    final uri = Uri.parse('$_baseUrl/teacher/courses/$courseId/quiz');

    final response = await _client.delete(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(
          'Erreur suppression quiz (${response.statusCode}) : ${response.body}');
    }
  }

  // Réinitialiser les tentatives de quiz d'un étudiant
  Future<void> resetStudentQuizAttempts(int courseId, int studentId) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Token manquant, merci de vous reconnecter.');
    }

    final uri = Uri.parse('$_baseUrl/teacher/courses/$courseId/students/$studentId/quiz-attempts');

    final response = await _client.delete(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 204) {
      throw Exception(
          'Erreur réinitialisation tentatives (${response.statusCode}) : ${response.body}');
    }
  }

  // Réinitialiser la progression du cours d'un étudiant
  Future<void> resetStudentCourseProgress(int courseId, int studentId) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Token manquant, merci de vous reconnecter.');
    }

    final uri = Uri.parse('$_baseUrl/teacher/courses/$courseId/students/$studentId/reset-progress');

    final response = await _client.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception(
          'Erreur réinitialisation progression (${response.statusCode}) : ${response.body}');
    }
  }

  // Créer un quiz standalone (sans cours)
  Future<Quiz> createStandaloneQuiz({
    required String title,
    String? description,
    int? passingScore,
    int? maxAttempts,
    required String level, // BEGINNER, INTERMEDIATE, ADVANCED
    required List<Map<String, dynamic>> questions,
  }) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Token manquant, merci de vous reconnecter.');
    }

    final uri = Uri.parse('$_baseUrl/teacher/courses/quiz');

    final body = <String, dynamic>{
      'title': title,
      'level': level,
      'questions': questions,
    };

    if (description != null) body['description'] = description;
    if (passingScore != null) body['passingScore'] = passingScore;
    if (maxAttempts != null) body['maxAttempts'] = maxAttempts;

    final response = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return Quiz.fromJson(data);
    } else {
      throw Exception(
          'Erreur création quiz (${response.statusCode}) : ${response.body}');
    }
  }
}
