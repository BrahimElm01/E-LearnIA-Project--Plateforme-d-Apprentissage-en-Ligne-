// lib/models/student_course.dart
class StudentCourse {
  final int id;
  final String title;
  final String description;
  final String teacherName;
  final String? imageUrl;
  final double progress; // 0..100 (en %)
  final bool completed;

  const StudentCourse({
    required this.id,
    required this.title,
    required this.description,
    required this.teacherName,
    this.imageUrl,
    this.progress = 0.0,
    this.completed = false,
  });

  factory StudentCourse.fromJson(Map<String, dynamic> json) {
    // format Postman :
    // {
    //   "id": 4,
    //   "title": "...",
    //   "description": "...",
    //   "imageUrl": null,
    //   "teacher": { "fullName": "mehdi", ... },
    //   "published": false,
    //   "progress": 0.0,
    //   "completed": false
    // }
    final teacher = json['teacher'] as Map<String, dynamic>?;

    return StudentCourse(
      id: (json['id'] ?? 0) as int,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      teacherName: teacher?['fullName']?.toString() ?? '',
      imageUrl: json['imageUrl'] as String?,
      // pas encore géré côté backend → 0%
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      completed: (json['completed'] as bool?) ?? false,
    );
  }
}
