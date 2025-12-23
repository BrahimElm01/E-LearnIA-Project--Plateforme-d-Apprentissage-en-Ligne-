class CourseAnalytics {
  final int totalStudents;
  final int activeCourses;
  final double avgRating;

  CourseAnalytics({
    required this.totalStudents,
    required this.activeCourses,
    required this.avgRating,
  });

  factory CourseAnalytics.fromJson(Map<String, dynamic> json) {
    return CourseAnalytics(
      totalStudents: (json['totalStudents'] as num?)?.toInt() ?? 0,
      activeCourses: (json['activeCourses'] as num?)?.toInt() ?? 0,
      avgRating: (json['avgRating'] as num?)?.toDouble() ?? 0.0,
    );
  }
}







