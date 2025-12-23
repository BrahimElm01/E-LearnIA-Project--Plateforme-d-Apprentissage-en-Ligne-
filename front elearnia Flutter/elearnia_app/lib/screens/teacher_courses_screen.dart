import 'package:flutter/material.dart';

import '../user.dart';
import '../services/course_service.dart';
import 'manage_course_lessons_screen.dart';
import 'edit_course_screen.dart';
import '../widgets/safe_network_image.dart';

class TeacherCoursesScreen extends StatefulWidget {
  final User user;

  const TeacherCoursesScreen({
    super.key,
    required this.user,
  });

  @override
  State<TeacherCoursesScreen> createState() => _TeacherCoursesScreenState();
}

class _TeacherCoursesScreenState extends State<TeacherCoursesScreen> {
  static const background = Color(0xFFF5F5F5);

  final CourseService _courseService = CourseService();
  bool _isLoading = true;
  String? _error;
  List<TeacherCourse> _courses = [];

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    try {
      final courses = await _courseService.getMyTeacherCourses();
      if (!mounted) return;
      setState(() {
        _courses = courses;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteCourse(TeacherCourse course) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le cours'),
        content: Text('Êtes-vous sûr de vouloir supprimer "${course.title}" ?\n\nCette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _courseService.deleteCourse(course.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cours supprimé avec succès'),
          backgroundColor: Colors.green,
        ),
      );
      _loadCourses();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la suppression : $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'My Courses',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Vos cours créés.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                    ? Center(child: Text('Erreur : $_error'))
                    : _courses.isEmpty
                    ? const Center(
                  child: Text('Aucun cours pour le moment.'),
                )
                    : ListView.separated(
                  itemCount: _courses.length,
                  separatorBuilder: (_, __) =>
                  const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final course = _courses[index];
                    return _TeacherCourseCard(
                      course: course,
                      onManageLessons: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ManageCourseLessonsScreen(
                              courseId: course.id,
                              courseTitle: course.title,
                            ),
                          ),
                        ).then((_) {
                          // Recharger la liste après retour
                          _loadCourses();
                        });
                      },
                      onEdit: () async {
                        final result = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                            builder: (_) => EditCourseScreen(course: course),
                          ),
                        );
                        if (result == true) {
                          // Recharger la liste après modification
                          _loadCourses();
                        }
                      },
                      onDelete: () => _deleteCourse(course),
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

class _TeacherCourseCard extends StatelessWidget {
  final TeacherCourse course;
  final VoidCallback onManageLessons;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TeacherCourseCard({
    required this.course,
    required this.onManageLessons,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image du cours
          if (course.imageUrl != null && course.imageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SafeNetworkImage(
                imageUrl: SafeNetworkImage.normalizeImageUrl(course.imageUrl),
                width: double.infinity,
                height: 120,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.play_circle_outline,
                size: 48,
                color: Colors.grey,
              ),
            ),
          const SizedBox(height: 12),
          Text(
            course.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            course.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                course.published ? 'Publié' : 'Brouillon',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Modifier', style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: onManageLessons,
                      icon: const Icon(Icons.video_library, size: 16),
                      label: const Text('Vidéos', style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                      label: const Text('Supp.', style: TextStyle(color: Colors.red, fontSize: 12)),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
