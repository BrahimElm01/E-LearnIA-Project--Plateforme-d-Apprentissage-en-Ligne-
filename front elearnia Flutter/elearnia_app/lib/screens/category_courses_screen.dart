import 'package:flutter/material.dart';
import '../models/student_course.dart';
import 'course_detail_screen.dart';
import '../widgets/safe_network_image.dart';

class CategoryCoursesScreen extends StatelessWidget {
  final String categoryName;
  final List<StudentCourse> courses;
  final Color categoryColor;
  final IconData categoryIcon;

  const CategoryCoursesScreen({
    super.key,
    required this.categoryName,
    required this.courses,
    required this.categoryColor,
    required this.categoryIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: categoryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(categoryIcon, color: categoryColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                categoryName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
      body: courses.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    categoryIcon,
                    size: 64,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun cours dans cette catégorie',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: courses.length,
              itemBuilder: (context, index) {
                final course = courses[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _CourseCard(
                    course: course,
                    categoryColor: categoryColor,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CourseDetailScreen(course: course),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final StudentCourse course;
  final Color categoryColor;
  final VoidCallback onTap;

  const _CourseCard({
    required this.course,
    required this.categoryColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: categoryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: course.imageUrl != null && course.imageUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SafeNetworkImage(
                        imageUrl: SafeNetworkImage.normalizeImageUrl(course.imageUrl),
                        fit: BoxFit.cover,
                      ),
                    )
                  : Icon(
                      Icons.play_circle_outline,
                      color: categoryColor,
                      size: 32,
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (course.teacherName.isNotEmpty)
                    Row(
                      children: [
                        Icon(Icons.person_outline, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          course.teacherName,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  // Toujours afficher le progrès, même s'il est à 0%
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: course.progress / 100,
                    minHeight: 4,
                    backgroundColor: Colors.grey[200]!,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      course.completed 
                          ? Colors.green 
                          : course.progress > 0 
                              ? categoryColor 
                              : Colors.grey[400]!,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    course.progress > 0
                        ? '${course.progress.toStringAsFixed(0)}% complété'
                        : course.completed
                            ? 'Terminé'
                            : 'Non commencé',
                    style: TextStyle(
                      fontSize: 11,
                      color: course.progress > 0 || course.completed
                          ? Colors.grey[600]!
                          : Colors.grey[500]!,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}











