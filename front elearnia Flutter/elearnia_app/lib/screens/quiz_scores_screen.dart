import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/course_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import '../config/api_config.dart';

class QuizScoresScreen extends StatefulWidget {
  final User user;

  const QuizScoresScreen({super.key, required this.user});

  @override
  State<QuizScoresScreen> createState() => _QuizScoresScreenState();
}

class _QuizScoresScreenState extends State<QuizScoresScreen> {
  final CourseService _courseService = CourseService();
  final AuthService _authService = AuthService();
  final http.Client _client = http.Client();
  static String get _baseUrl => ApiConfig.baseUrl;

  List<AllQuizzesScores> _quizzesScores = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadScores();
  }

  Future<void> _loadScores() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Token manquant');
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
        setState(() {
          _quizzesScores = data.map((json) => AllQuizzesScores.fromJson(json as Map<String, dynamic>)).toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Scores des quizzes'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadScores,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
                      const SizedBox(height: 16),
                      Text(
                        'Erreur',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: theme.colorScheme.secondary),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadScores,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : _quizzesScores.isEmpty
                  ? Center(
                      child: Text(
                        'Aucun quiz trouvé',
                        style: TextStyle(color: theme.colorScheme.secondary),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadScores,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _quizzesScores.length,
                        itemBuilder: (context, index) {
                          final quizScores = _quizzesScores[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: ExpansionTile(
                              title: Text(
                                quizScores.quizTitle,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Cours: ${quizScores.courseTitle}'),
                                  Text('Niveau: ${quizScores.level}'),
                                  Text('${quizScores.scores.length} tentative(s)'),
                                ],
                              ),
                              children: quizScores.scores.isEmpty
                                  ? [
                                      Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Text(
                                          'Aucune tentative pour ce quiz',
                                          style: TextStyle(color: theme.colorScheme.secondary),
                                        ),
                                      ),
                                    ]
                                  : quizScores.scores.map((score) {
                                      return ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: score.passed
                                              ? Colors.green.withValues(alpha: 0.2)
                                              : Colors.red.withValues(alpha: 0.2),
                                          child: Icon(
                                            score.passed ? Icons.check : Icons.close,
                                            color: score.passed ? Colors.green : Colors.red,
                                          ),
                                        ),
                                        title: Text(score.studentName),
                                        subtitle: Text(score.studentEmail),
                                        trailing: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              '${score.score.toStringAsFixed(1)}%',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: score.passed ? Colors.green : Colors.red,
                                                fontSize: 16,
                                              ),
                                            ),
                                            Text(
                                              'Tentative ${score.attemptNumber}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: theme.colorScheme.secondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

class AllQuizzesScores {
  final int quizId;
  final String quizTitle;
  final String level;
  final String courseTitle;
  final List<StudentQuizScore> scores;

  AllQuizzesScores({
    required this.quizId,
    required this.quizTitle,
    required this.level,
    required this.courseTitle,
    required this.scores,
  });

  factory AllQuizzesScores.fromJson(Map<String, dynamic> json) {
    return AllQuizzesScores(
      quizId: json['quizId'] as int,
      quizTitle: json['quizTitle'] as String,
      level: json['level'] as String? ?? 'BEGINNER',
      courseTitle: json['courseTitle'] as String? ?? 'Quiz standalone',
      scores: (json['scores'] as List<dynamic>?)
              ?.map((s) => StudentQuizScore.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class StudentQuizScore {
  final int attemptId;
  final int studentId;
  final String studentName;
  final String studentEmail;
  final double score;
  final bool passed;
  final int attemptNumber;
  final String completedAt;

  StudentQuizScore({
    required this.attemptId,
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    required this.score,
    required this.passed,
    required this.attemptNumber,
    required this.completedAt,
  });

  factory StudentQuizScore.fromJson(Map<String, dynamic> json) {
    return StudentQuizScore(
      attemptId: json['attemptId'] as int,
      studentId: json['studentId'] as int,
      studentName: json['studentName'] as String? ?? 'Inconnu',
      studentEmail: json['studentEmail'] as String? ?? '',
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      passed: (json['passed'] as bool?) ?? false,
      attemptNumber: (json['attemptNumber'] as int?) ?? 0,
      completedAt: json['completedAt'] as String? ?? '',
    );
  }
}










