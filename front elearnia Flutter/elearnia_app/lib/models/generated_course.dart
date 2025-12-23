class GeneratedCourse {
  final String title;
  final String description;
  final String summary;
  final String? imageUrl; // Miniature générée
  final List<String> objectives;
  final List<GeneratedLesson> lessons;
  final GeneratedQuiz? quiz;

  GeneratedCourse({
    required this.title,
    required this.description,
    required this.summary,
    this.imageUrl,
    required this.objectives,
    required this.lessons,
    this.quiz,
  });

  factory GeneratedCourse.fromJson(Map<String, dynamic> json) {
    return GeneratedCourse(
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString(),
      objectives: (json['objectives'] as List<dynamic>?)
              ?.map((obj) => obj.toString())
              .toList() ??
          [],
      lessons: (json['lessons'] as List<dynamic>?)
              ?.map((lesson) => GeneratedLesson.fromJson(lesson as Map<String, dynamic>))
              .toList() ??
          [],
      quiz: json['quiz'] != null
          ? GeneratedQuiz.fromJson(json['quiz'] as Map<String, dynamic>)
          : null,
    );
  }
}

class GeneratedLesson {
  final String title;
  final String description;
  final int orderIndex;
  final int estimatedDuration;
  final String? videoUrl; // URL de la vidéo YouTube

  GeneratedLesson({
    required this.title,
    required this.description,
    required this.orderIndex,
    required this.estimatedDuration,
    this.videoUrl,
  });

  factory GeneratedLesson.fromJson(Map<String, dynamic> json) {
    return GeneratedLesson(
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      orderIndex: json['orderIndex'] as int? ?? 0,
      estimatedDuration: json['estimatedDuration'] as int? ?? 0,
      videoUrl: json['videoUrl']?.toString(),
    );
  }
}

class GeneratedQuiz {
  final String title;
  final String description;
  final List<GeneratedQuestion> questions;

  GeneratedQuiz({
    required this.title,
    required this.description,
    required this.questions,
  });

  factory GeneratedQuiz.fromJson(Map<String, dynamic> json) {
    return GeneratedQuiz(
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      questions: (json['questions'] as List<dynamic>?)
              ?.map((q) => GeneratedQuestion.fromJson(q as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class GeneratedQuestion {
  final String text;
  final List<String> options;
  final String correctAnswer;
  final int points;

  GeneratedQuestion({
    required this.text,
    required this.options,
    required this.correctAnswer,
    required this.points,
  });

  factory GeneratedQuestion.fromJson(Map<String, dynamic> json) {
    return GeneratedQuestion(
      text: json['text']?.toString() ?? '',
      options: (json['options'] as List<dynamic>?)
              ?.map((opt) => opt.toString())
              .toList() ??
          [],
      correctAnswer: json['correctAnswer']?.toString() ?? '',
      points: json['points'] as int? ?? 1,
    );
  }
}

