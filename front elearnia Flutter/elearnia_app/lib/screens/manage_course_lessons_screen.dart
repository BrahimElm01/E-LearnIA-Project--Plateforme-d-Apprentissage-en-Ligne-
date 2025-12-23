import 'package:flutter/material.dart';
import '../services/course_service.dart';
import '../models/lesson.dart';
import '../models/quiz.dart';
import 'add_lesson_screen.dart';
import 'create_quiz_screen.dart';
import 'manage_reviews_screen.dart';

class ManageCourseLessonsScreen extends StatefulWidget {
  final int courseId;
  final String courseTitle;

  const ManageCourseLessonsScreen({
    super.key,
    required this.courseId,
    required this.courseTitle,
  });

  @override
  State<ManageCourseLessonsScreen> createState() => _ManageCourseLessonsScreenState();
}

class _ManageCourseLessonsScreenState extends State<ManageCourseLessonsScreen> {
  final CourseService _courseService = CourseService();
  List<Lesson> _lessons = [];
  Quiz? _quiz;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLessons();
    _loadQuiz();
  }

  Future<void> _loadLessons() async {
    try {
      final lessons = await _courseService.getCourseLessons(widget.courseId);
      if (!mounted) return;
      setState(() {
        _lessons = lessons;
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

  Future<void> _loadQuiz() async {
    try {
      final quiz = await _courseService.getQuiz(widget.courseId);
      if (!mounted) return;
      setState(() {
        _quiz = quiz;
      });
    } catch (e) {
      // Ignorer les erreurs (quiz peut ne pas exister)
      if (mounted) {
        setState(() {
          _quiz = null;
        });
      }
    }
  }

  Future<void> _addLesson() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddLessonScreen(courseId: widget.courseId),
      ),
    );

    if (result == true) {
      _loadLessons(); // Recharger la liste
    }
  }

  Future<void> _deleteLesson(Lesson lesson) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer la leçon'),
        content: Text('Êtes-vous sûr de vouloir supprimer "${lesson.title}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _courseService.deleteLesson(widget.courseId, lesson.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Leçon supprimée')),
      );
      _loadLessons();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  Future<void> _manageQuiz() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CreateQuizScreen(
          courseId: widget.courseId,
          courseTitle: widget.courseTitle,
          existingQuiz: _quiz,
        ),
      ),
    );

    if (result == true) {
      _loadQuiz(); // Recharger le quiz
    }
  }

  Future<void> _manageReviews() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ManageReviewsScreen(
          courseId: widget.courseId,
          courseTitle: widget.courseTitle,
        ),
      ),
    );
  }

  Future<void> _deleteQuiz() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le quiz'),
        content: const Text('Êtes-vous sûr de vouloir supprimer ce quiz ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _courseService.deleteQuiz(widget.courseId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quiz supprimé')),
      );
      _loadQuiz();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFFF5F5F5);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        title: Text(
          'Vidéos: ${widget.courseTitle}',
          style: const TextStyle(color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.reviews_outlined),
            tooltip: 'Gérer les avis',
            onPressed: _manageReviews,
            color: Colors.black,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Erreur: $_error',
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadLessons,
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  )
                : _lessons.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.video_library_outlined,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Aucune vidéo pour ce cours',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: _addLesson,
                              icon: const Icon(Icons.add),
                              label: const Text('Ajouter une vidéo'),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          Expanded(
                            child: ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: _lessons.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final lesson = _lessons[index];
                                return Card(
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.grey.shade200,
                                      child: const Icon(Icons.play_arrow, color: Colors.black),
                                    ),
                                    title: Text(lesson.title),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (lesson.description != null)
                                          Text(
                                            lesson.description!,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            if (lesson.duration != null) ...[
                                              const Icon(Icons.access_time, size: 14),
                                              const SizedBox(width: 4),
                                              Text('${lesson.duration} min'),
                                              const SizedBox(width: 12),
                                            ],
                                            const Icon(Icons.sort, size: 14),
                                            const SizedBox(width: 4),
                                            Text('Ordre: ${lesson.orderIndex}'),
                                          ],
                                        ),
                                      ],
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _deleteLesson(lesson),
                                    ),
                                    onTap: () {
                                      // Optionnel: éditer la leçon
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                          // Section Quiz
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.1),
                                        blurRadius: 4,
                                        offset: const Offset(0, -2),
                                      ),
                                    ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.quiz, color: Colors.black),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Quiz du cours',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (_quiz != null)
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: _deleteQuiz,
                                        tooltip: 'Supprimer le quiz',
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                if (_quiz != null) ...[
                                  Text(
                                    'Titre: ${_quiz!.title}',
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 4),
                                  Text('${_quiz!.questions.length} question(s)'),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Score minimum: ${_quiz!.passingScore}% | Tentatives: ${_quiz!.maxAttempts}',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                  ),
                                ] else ...[
                                  Text(
                                    'Aucun quiz créé pour ce cours',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _manageQuiz,
                  icon: Icon(_quiz != null ? Icons.edit : Icons.quiz),
                  label: Text(_quiz != null ? 'Modifier quiz' : 'Créer quiz'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _addLesson,
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter une vidéo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

