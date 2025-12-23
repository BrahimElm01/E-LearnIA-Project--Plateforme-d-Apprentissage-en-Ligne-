class Lesson {
  final int id;
  final String title;
  final String? description;
  final String videoUrl;
  final int? duration; // en minutes
  final int orderIndex;

  const Lesson({
    required this.id,
    required this.title,
    this.description,
    required this.videoUrl,
    this.duration,
    required this.orderIndex,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['id'] as int,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      videoUrl: json['videoUrl']?.toString() ?? '',
      duration: json['duration'] as int?,
      orderIndex: json['orderIndex'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'videoUrl': videoUrl,
      'duration': duration,
      'orderIndex': orderIndex,
    };
  }
}


