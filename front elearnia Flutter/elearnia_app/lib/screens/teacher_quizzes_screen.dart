import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/quiz.dart';
import '../services/quiz_service.dart';
import '../services/course_service.dart';
import 'edit_quiz_screen.dart';

class TeacherQuizzesScreen extends StatefulWidget {
  final User user;

  const TeacherQuizzesScreen({
    super.key,
    required this.user,
  });

  @override
  State<TeacherQuizzesScreen> createState() => _TeacherQuizzesScreenState();
}

class _TeacherQuizzesScreenState extends State<TeacherQuizzesScreen> {
  final QuizService _quizService = QuizService();
  final CourseService _courseService = CourseService();
  
  List<Quiz> _quizzes = [];
  List<Quiz> _filteredQuizzes = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String _filterType = 'all'; // 'all', 'standalone', 'course'

  @override
  void initState() {
    super.initState();
    _loadQuizzes();
  }

  Future<void> _loadQuizzes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final quizzes = await _quizService.getTeacherQuizzes();
      setState(() {
        _quizzes = quizzes;
        _filteredQuizzes = quizzes;
        _isLoading = false;
      });
      _applyFilters();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    List<Quiz> filtered = List.from(_quizzes);

    // Filtre par type
    if (_filterType == 'standalone') {
      filtered = filtered.where((q) => q.courseId == null).toList();
    } else if (_filterType == 'course') {
      filtered = filtered.where((q) => q.courseId != null).toList();
    }

    // Filtre par recherche
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((quiz) {
        return quiz.title.toLowerCase().contains(query) ||
            quiz.description.toLowerCase().contains(query);
      }).toList();
    }

    setState(() {
      _filteredQuizzes = filtered;
    });
  }

  Future<void> _deleteQuiz(Quiz quiz) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le quiz'),
        content: Text('Êtes-vous sûr de vouloir supprimer "${quiz.title}" ? Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      if (quiz.courseId != null) {
        await _quizService.deleteCourseQuiz(quiz.courseId!);
      } else {
        await _quizService.deleteStandaloneQuiz(quiz.id);
      }
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quiz supprimé avec succès')),
      );
      
      _loadQuizzes();
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la suppression: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _associateQuizToCourse(Quiz quiz) async {
    if (quiz.courseId != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ce quiz est déjà associé à un cours')),
      );
      return;
    }

    // Charger la liste des cours du professeur
    try {
      final courses = await _courseService.getMyTeacherCourses();
      
      if (!mounted) return;

      if (courses.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vous devez d\'abord créer un cours')),
        );
        return;
      }

      final selectedCourse = await showDialog<TeacherCourse>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Associer le quiz à un cours'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: courses.length,
              itemBuilder: (context, index) {
                final course = courses[index];
                return ListTile(
                  title: Text(course.title),
                  subtitle: Text(course.description.length > 50 
                      ? '${course.description.substring(0, 50)}...' 
                      : course.description),
                  onTap: () => Navigator.of(context).pop(course),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
          ],
        ),
      );

      if (selectedCourse == null) return;

      // Vérifier si un quiz existe déjà pour ce cours
      bool hasExistingQuiz = false;
      try {
        final existingQuiz = await _courseService.getQuiz(selectedCourse.id);
        hasExistingQuiz = existingQuiz != null;
      } catch (e) {
        // Si erreur 404, pas de quiz existant
        hasExistingQuiz = false;
      }

      // Si un quiz existe déjà, demander confirmation pour le remplacer
      if (hasExistingQuiz) {
        final replace = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Quiz existant'),
            content: const Text(
              'Un quiz existe déjà pour ce cours. Voulez-vous le remplacer par ce quiz standalone ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Remplacer'),
              ),
            ],
          ),
        );

        if (replace != true) return;
      }

      try {
        await _quizService.associateQuizToCourse(
          quizId: quiz.id,
          courseId: selectedCourse.id,
          replaceExisting: hasExistingQuiz,
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(hasExistingQuiz
                ? 'Quiz remplacé avec succès'
                : 'Quiz associé au cours avec succès'),
            backgroundColor: Colors.green,
          ),
        );

        _loadQuizzes();
      } catch (e) {
        if (!mounted) return;

        String errorMessage = e.toString();
        if (errorMessage.contains('existe déjà')) {
          errorMessage = 'Un quiz existe déjà pour ce cours. Supprimez-le d\'abord ou modifiez-le.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'association: $errorMessage'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du chargement des cours: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Mes Quizzes'),
      ),
      body: Column(
        children: [
          // Barre de recherche et filtres
          Container(
            padding: const EdgeInsets.all(16),
            color: theme.cardColor,
            child: Column(
              children: [
                // Barre de recherche
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Rechercher un quiz...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: theme.scaffoldBackgroundColor,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                    _applyFilters();
                  },
                ),
                const SizedBox(height: 12),
                // Filtres
                Row(
                  children: [
                    Expanded(
                      child: _FilterChip(
                        label: 'Tous',
                        isSelected: _filterType == 'all',
                        onTap: () {
                          setState(() {
                            _filterType = 'all';
                          });
                          _applyFilters();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _FilterChip(
                        label: 'Standalone',
                        isSelected: _filterType == 'standalone',
                        onTap: () {
                          setState(() {
                            _filterType = 'standalone';
                          });
                          _applyFilters();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _FilterChip(
                        label: 'Liés aux cours',
                        isSelected: _filterType == 'course',
                        onTap: () {
                          setState(() {
                            _filterType = 'course';
                          });
                          _applyFilters();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Liste des quizzes
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 64, color: Colors.red),
                            const SizedBox(height: 16),
                            Text('Erreur: $_error'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadQuizzes,
                              child: const Text('Réessayer'),
                            ),
                          ],
                        ),
                      )
                    : _filteredQuizzes.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.quiz_outlined, size: 64, color: theme.colorScheme.secondary),
                                const SizedBox(height: 16),
                                Text(
                                  _searchQuery.isNotEmpty
                                      ? 'Aucun quiz trouvé'
                                      : 'Aucun quiz créé',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: theme.colorScheme.secondary,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadQuizzes,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredQuizzes.length,
                              itemBuilder: (context, index) {
                                final quiz = _filteredQuizzes[index];
                                return _QuizCard(
                                  quiz: quiz,
                                  onEdit: () async {
                                    final result = await Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => EditQuizScreen(quiz: quiz),
                                      ),
                                    );
                                    if (result == true) {
                                      _loadQuizzes();
                                    }
                                  },
                                  onDelete: () => _deleteQuiz(quiz),
                                  onAssociate: quiz.courseId == null
                                      ? () => _associateQuizToCourse(quiz)
                                      : null,
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.secondary.withValues(alpha: 0.3),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : theme.colorScheme.secondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

class _QuizCard extends StatelessWidget {
  final Quiz quiz;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onAssociate;

  const _QuizCard({
    required this.quiz,
    required this.onEdit,
    required this.onDelete,
    this.onAssociate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quiz.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (quiz.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          quiz.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.colorScheme.secondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                if (quiz.level != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getLevelColor(quiz.level!).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      quiz.level!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getLevelColor(quiz.level!),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(
                  icon: Icons.help_outline,
                  label: '${quiz.questions.length} questions',
                ),
                _InfoChip(
                  icon: Icons.check_circle_outline,
                  label: 'Score min: ${quiz.passingScore}%',
                ),
                _InfoChip(
                  icon: Icons.repeat,
                  label: '${quiz.maxAttempts} tent. max',
                ),
              ],
            ),
            if (quiz.courseId != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.book, size: 16, color: primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      'Quiz lié à un cours',
                      style: TextStyle(
                        fontSize: 12,
                        color: primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Modifier'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                if (onAssociate != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onAssociate,
                      icon: const Icon(Icons.link, size: 18),
                      label: const Text('Associer'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete, size: 18),
                    label: const Text('Supprimer'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getLevelColor(String level) {
    switch (level.toUpperCase()) {
      case 'BEGINNER':
      case 'DÉBUTANT':
        return Colors.green;
      case 'INTERMEDIATE':
      case 'INTERMÉDIAIRE':
        return Colors.orange;
      case 'ADVANCED':
      case 'AVANCÉ':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.secondary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.secondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

