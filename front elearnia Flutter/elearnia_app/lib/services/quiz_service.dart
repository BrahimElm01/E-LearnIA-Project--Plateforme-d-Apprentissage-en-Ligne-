import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../config/api_config.dart';
import '../models/quiz.dart';
import 'course_service.dart';

class QuizService {
  static String get _baseUrl => ApiConfig.baseUrl;
  final http.Client _client = http.Client();
  final AuthService _authService = AuthService();
  final CourseService _courseService = CourseService();

  Future<String?> _getToken() async {
    return _authService.getToken();
  }

  Future<Quiz> getQuizByCourse(int courseId) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Token manquant, merci de vous reconnecter.');
    }

    final uri = Uri.parse('$_baseUrl/student/quizzes/course/$courseId');

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
    } else {
      throw Exception(
          'Erreur chargement quiz (${response.statusCode}) : ${response.body}');
    }
  }

  Future<QuizResult> submitQuiz(int courseId, Map<int, String> answers) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Token manquant, merci de vous reconnecter.');
    }

    final uri = Uri.parse('$_baseUrl/student/quizzes/course/$courseId/submit');

    // Convertir Map<int, String> en Map<String, String> pour JSON
    final answersJson = answers.map((key, value) => MapEntry(key.toString(), value));

    final response = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'answers': answersJson}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return QuizResult.fromJson(data);
    } else {
      throw Exception(
          'Erreur soumission quiz (${response.statusCode}) : ${response.body}');
    }
  }

  // Récupérer tous les quizzes disponibles (standalone)
  Future<List<QuizSummary>> getAvailableQuizzes({String? level}) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Token manquant, merci de vous reconnecter.');
    }

    final uri = Uri.parse('$_baseUrl/student/quizzes/available')
        .replace(queryParameters: level != null && level != 'ALL' 
            ? {'level': level} 
            : {});

    final response = await _client.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      return data.map((json) => QuizSummary.fromJson(json as Map<String, dynamic>)).toList();
    } else {
      throw Exception(
          'Erreur chargement quizzes (${response.statusCode}) : ${response.body}');
    }
  }

  // Récupérer un quiz standalone par ID
  Future<Quiz> getQuizById(int quizId) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Token manquant, merci de vous reconnecter.');
    }

    final uri = Uri.parse('$_baseUrl/student/quizzes/$quizId');

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
    } else {
      throw Exception(
          'Erreur chargement quiz (${response.statusCode}) : ${response.body}');
    }
  }

  // Soumettre un quiz standalone
  Future<QuizResult> submitStandaloneQuiz(int quizId, Map<int, String> answers) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Token manquant, merci de vous reconnecter.');
    }

    final uri = Uri.parse('$_baseUrl/student/quizzes/$quizId/submit');

    // Convertir Map<int, String> en Map<String, String> pour JSON
    final answersJson = answers.map((key, value) => MapEntry(key.toString(), value));

    final response = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'answers': answersJson}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return QuizResult.fromJson(data);
    } else {
      throw Exception(
          'Erreur soumission quiz (${response.statusCode}) : ${response.body}');
    }
  }

  // Générer un quiz par IA (pour les professeurs)
  Future<Quiz> generateQuizWithAI({
    required String topic,
    required String difficulty, // BEGINNER, INTERMEDIATE, ADVANCED
  }) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Token manquant, merci de vous reconnecter.');
    }

    final uri = Uri.parse('$_baseUrl/teacher/courses/quiz/generate');

    final body = <String, dynamic>{
      'topic': topic,
      'difficulty': difficulty,
    };

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
          'Erreur génération quiz (${response.statusCode}) : ${response.body}');
    }
  }

  // Récupérer tous les quizzes du professeur
  Future<List<Quiz>> getTeacherQuizzes() async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Token manquant, merci de vous reconnecter.');
    }

    final uri = Uri.parse('$_baseUrl/teacher/courses/quizzes');

    final response = await _client.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      return data.map((json) => Quiz.fromJson(json as Map<String, dynamic>)).toList();
    } else {
      throw Exception(
          'Erreur chargement quizzes (${response.statusCode}) : ${response.body}');
    }
  }

  // Récupérer tous les scores des quizzes
  Future<List<Map<String, dynamic>>> getAllQuizzesScores() async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Token manquant, merci de vous reconnecter.');
    }

    final uri = Uri.parse('$_baseUrl/teacher/courses/quizzes/scores');

    final response = await _client.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      return data.map((json) => json as Map<String, dynamic>).toList();
    } else {
      throw Exception(
          'Erreur chargement scores quizzes (${response.statusCode}) : ${response.body}');
    }
  }

  // Modifier un quiz standalone
  Future<Quiz> updateStandaloneQuiz({
    required int quizId,
    String? title,
    String? description,
    int? passingScore,
    int? maxAttempts,
    String? level,
    List<Map<String, dynamic>>? questions,
  }) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Token manquant, merci de vous reconnecter.');
    }

    final uri = Uri.parse('$_baseUrl/teacher/courses/quiz/$quizId');

    final body = <String, dynamic>{};
    if (title != null && title.isNotEmpty) body['title'] = title;
    if (description != null) body['description'] = description;
    if (passingScore != null) body['passingScore'] = passingScore;
    if (maxAttempts != null) body['maxAttempts'] = maxAttempts;
    if (level != null && level.isNotEmpty) body['level'] = level;
    if (questions != null) body['questions'] = questions; // Toujours envoyer les questions si fournies

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

  // Modifier un quiz de cours
  Future<Quiz> updateCourseQuiz({
    required int courseId,
    String? title,
    String? description,
    int? passingScore,
    int? maxAttempts,
    String? level,
    List<Map<String, dynamic>>? questions,
  }) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Token manquant, merci de vous reconnecter.');
    }

    final uri = Uri.parse('$_baseUrl/teacher/courses/$courseId/quiz');

    final body = <String, dynamic>{};
    if (title != null && title.isNotEmpty) body['title'] = title;
    if (description != null) body['description'] = description;
    if (passingScore != null) body['passingScore'] = passingScore;
    if (maxAttempts != null) body['maxAttempts'] = maxAttempts;
    if (level != null && level.isNotEmpty) body['level'] = level;
    if (questions != null) body['questions'] = questions; // Toujours envoyer les questions si fournies

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

  // Supprimer un quiz standalone
  Future<void> deleteStandaloneQuiz(int quizId) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Token manquant, merci de vous reconnecter.');
    }

    final uri = Uri.parse('$_baseUrl/teacher/courses/quiz/$quizId');

    final response = await _client.delete(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception(
          'Erreur suppression quiz (${response.statusCode}) : ${response.body}');
    }
  }

  // Supprimer un quiz de cours
  Future<void> deleteCourseQuiz(int courseId) async {
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

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception(
          'Erreur suppression quiz (${response.statusCode}) : ${response.body}');
    }
  }

  // Associer un quiz standalone à un cours
  // Note: Cette méthode crée un nouveau quiz pour le cours ou met à jour l'existant, puis supprime l'ancien standalone
  Future<Quiz> associateQuizToCourse({
    required int quizId,
    required int courseId,
    bool replaceExisting = false,
  }) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Token manquant, merci de vous reconnecter.');
    }

    // Récupérer le quiz standalone avec toutes les informations
    final quiz = await getStandaloneQuizForTeacher(quizId);
    
    // Vérifier d'abord si un quiz existe déjà pour ce cours
    Quiz? existingQuiz;
    try {
      existingQuiz = await _courseService.getQuiz(courseId);
    } catch (e) {
      // Si l'erreur est 404, c'est bon, il n'y a pas de quiz
      if (!e.toString().contains('404') && !e.toString().contains('NOT_FOUND')) {
        // Autre erreur, on continue quand même
      }
    }
    
    // Si un quiz existe déjà et qu'on ne veut pas le remplacer, lancer une exception
    if (existingQuiz != null && !replaceExisting) {
      throw Exception('Un quiz existe déjà pour ce cours. Supprimez-le d\'abord ou modifiez-le.');
    }
    
    // Si un quiz existe et qu'on veut le remplacer, le supprimer d'abord
    if (existingQuiz != null && replaceExisting) {
      try {
        await deleteCourseQuiz(courseId);
      } catch (e) {
        throw Exception('Erreur lors de la suppression du quiz existant: $e');
      }
    }
    
    // Créer un nouveau quiz pour le cours avec les mêmes données
    final uri = Uri.parse('$_baseUrl/teacher/courses/$courseId/quiz');

    final body = <String, dynamic>{
      'title': quiz.title,
      'description': quiz.description,
      'passingScore': quiz.passingScore,
      'maxAttempts': quiz.maxAttempts,
      'level': quiz.level ?? 'BEGINNER',
      'questions': quiz.questions.map((q) => {
        'text': q.text,
        'options': q.options,
        'correctAnswer': q.correctAnswer ?? '',
        'points': q.points,
      }).toList(),
    };

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
      // Supprimer l'ancien quiz standalone après avoir créé le nouveau
      try {
        await deleteStandaloneQuiz(quizId);
      } catch (e) {
        // Si la suppression échoue, on continue quand même
        print('Erreur lors de la suppression du quiz standalone: $e');
      }
      return Quiz.fromJson(data);
    } else {
      final errorBody = response.body;
      if (response.statusCode == 400 && errorBody.contains('existe déjà')) {
        throw Exception('Un quiz existe déjà pour ce cours. Supprimez-le d\'abord ou modifiez-le.');
      }
      throw Exception(
          'Erreur association quiz (${response.statusCode}) : $errorBody');
    }
  }

  // Récupérer un quiz standalone pour le professeur (avec les réponses)
  Future<Quiz> getStandaloneQuizForTeacher(int quizId) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Token manquant, merci de vous reconnecter.');
    }

    final uri = Uri.parse('$_baseUrl/teacher/courses/quiz/$quizId');

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
    } else {
      throw Exception(
          'Erreur chargement quiz (${response.statusCode}) : ${response.body}');
    }
  }
}

