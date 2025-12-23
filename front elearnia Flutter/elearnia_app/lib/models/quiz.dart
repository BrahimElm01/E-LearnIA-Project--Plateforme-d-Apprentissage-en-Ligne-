class Quiz {
  final int id;
  final String title;
  final String description;
  final int passingScore;
  final int maxAttempts;
  final int remainingAttempts; // Tentatives restantes
  final String? level; // BEGINNER, INTERMEDIATE, ADVANCED
  final int? courseId; // ID du cours si lié à un cours, null sinon
  final List<Question> questions;

  Quiz({
    required this.id,
    required this.title,
    required this.description,
    required this.passingScore,
    required this.maxAttempts,
    required this.remainingAttempts,
    this.level,
    this.courseId,
    required this.questions,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      passingScore: json['passingScore'] as int? ?? 75,
      maxAttempts: json['maxAttempts'] as int? ?? 3,
      remainingAttempts: json['remainingAttempts'] as int? ?? 0,
      level: json['level'] as String?,
      courseId: json['courseId'] as int?,
      questions: (json['questions'] as List<dynamic>?)
              ?.map((q) => Question.fromJson(q as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class QuizSummary {
  final int id;
  final String title;
  final String description;
  final int passingScore;
  final int maxAttempts;
  final int remainingAttempts;
  final String level; // BEGINNER, INTERMEDIATE, ADVANCED
  final int questionCount;

  QuizSummary({
    required this.id,
    required this.title,
    required this.description,
    required this.passingScore,
    required this.maxAttempts,
    required this.remainingAttempts,
    required this.level,
    required this.questionCount,
  });

  factory QuizSummary.fromJson(Map<String, dynamic> json) {
    return QuizSummary(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      passingScore: json['passingScore'] as int? ?? 75,
      maxAttempts: json['maxAttempts'] as int? ?? 3,
      remainingAttempts: json['remainingAttempts'] as int? ?? 0,
      level: json['level'] as String? ?? 'BEGINNER',
      questionCount: json['questionCount'] as int? ?? 0,
    );
  }
}

class Question {
  final int id;
  final String text;
  final List<String> options;
  final int points;
  final String? correctAnswer; // Pour l'édition côté professeur

  Question({
    required this.id,
    required this.text,
    required this.options,
    required this.points,
    this.correctAnswer,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as int,
      text: json['text'] as String,
      options: (json['options'] as List<dynamic>?)
              ?.map((o) => o as String)
              .toList() ??
          [],
      points: json['points'] as int? ?? 1,
      correctAnswer: json['correctAnswer'] as String?,
    );
  }
}

class QuizResult {
  final double score;
  final bool passed;
  final int attemptNumber;
  final int remainingAttempts;
  final bool courseCompleted;

  QuizResult({
    required this.score,
    required this.passed,
    required this.attemptNumber,
    required this.remainingAttempts,
    required this.courseCompleted,
  });

  factory QuizResult.fromJson(Map<String, dynamic> json) {
    return QuizResult(
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      passed: (json['passed'] as bool?) ?? false,
      attemptNumber: (json['attemptNumber'] as int?) ?? 0,
      remainingAttempts: (json['remainingAttempts'] as int?) ?? 0,
      courseCompleted: (json['courseCompleted'] as bool?) ?? false,
    );
  }
}

