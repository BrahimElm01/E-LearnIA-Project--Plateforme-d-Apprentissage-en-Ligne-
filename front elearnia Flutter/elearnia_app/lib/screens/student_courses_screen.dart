import 'package:flutter/material.dart';
import '../../services/course_service.dart';
import '../models/student_course.dart';
import '../user.dart';
import '../widgets/safe_network_image.dart';
import 'course_detail_screen.dart';

class StudentCoursesScreen extends StatefulWidget {
  final User user;

  const StudentCoursesScreen({
    super.key,
    required this.user,
  });

  @override
  State<StudentCoursesScreen> createState() => _StudentCoursesScreenState();
}

class _StudentCoursesScreenState extends State<StudentCoursesScreen> {
  final CourseService _courseService = CourseService();
  late Future<List<StudentCourse>> _futureCourses;
  
  void _refreshCourses() {
    setState(() {
      _futureCourses = _courseService.getStudentCourses();
    });
  }

  @override
  void initState() {
    super.initState();
    _futureCourses = _courseService.getStudentCourses();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Courses',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Les cours disponibles pour toi.',
                style: TextStyle(
                  color: theme.colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: FutureBuilder<List<StudentCourse>>(
                  future: _futureCourses,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Erreur : ${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      );
                    }

                    final courses = snapshot.data ?? [];

                    if (courses.isEmpty) {
                      return Center(
                        child: Text(
                          'Aucun cours pour le moment.',
                          style: TextStyle(color: theme.colorScheme.secondary),
                        ),
                      );
                    }

                    return ListView.separated(
                      itemCount: courses.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final course = courses[index];
                        return _StudentCourseCard(
                          course: course,
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    CourseDetailScreen(course: course),
                              ),
                            );
                            // Recharger les cours quand on revient (pour mettre à jour les reviews)
                            _refreshCourses();
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StudentCourseCard extends StatelessWidget {
  final StudentCourse course;
  final VoidCallback onTap;

  const _StudentCourseCard({
    required this.course,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image ou Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(18),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SafeNetworkImage(
                  imageUrl: course.imageUrl,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  errorWidget: Icon(
                    Icons.play_arrow_rounded,
                    size: 32,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Infos cours
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    course.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap pour voir le cours',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Barre de progression
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                if (course.teacherName.isNotEmpty)
                                  Text(
                                    'Prof : ${course.teacherName}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.colorScheme.secondary,
                                    ),
                                  ),
                                Text(
                                  '${course.progress.toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: course.progress > 0
                                        ? Colors.blue.shade700
                                        : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: course.progress / 100,
                                minHeight: 6,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  course.progress == 100
                                      ? Colors.green
                                      : course.progress > 0
                                          ? Colors.blue
                                          : Colors.grey.shade300,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
