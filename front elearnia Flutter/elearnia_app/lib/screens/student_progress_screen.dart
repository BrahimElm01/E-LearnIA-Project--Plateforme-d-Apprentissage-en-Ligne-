import 'package:flutter/material.dart';
import '../services/progress_service.dart';
import '../services/course_service.dart';
import '../models/user.dart';
import '../widgets/safe_network_image.dart';

class StudentProgressScreen extends StatefulWidget {
  final User user;

  const StudentProgressScreen({super.key, required this.user});

  @override
  State<StudentProgressScreen> createState() => _StudentProgressScreenState();
}

class _StudentProgressScreenState extends State<StudentProgressScreen> {
  final ProgressService _progressService = ProgressService();
  final CourseService _courseService = CourseService();
  List<TeacherCourse> _courses = [];
  List<StudentProgress>? _selectedCourseProgress;
  int? _selectedCourseId;
  bool _isLoadingCourses = true;
  bool _isLoadingProgress = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    setState(() {
      _isLoadingCourses = true;
      _error = null;
    });

    try {
      final courses = await _courseService.getMyTeacherCourses();
      if (!mounted) return;
      setState(() {
        _courses = courses;
        _isLoadingCourses = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoadingCourses = false;
      });
    }
  }

  Future<void> _loadProgress(int courseId) async {
    setState(() {
      _isLoadingProgress = true;
      _selectedCourseId = courseId;
      _selectedCourseProgress = null;
      _error = null;
    });

    try {
      final progress = await _progressService.getStudentsProgress(courseId);
      if (!mounted) return;
      setState(() {
        _selectedCourseProgress = progress;
        _isLoadingProgress = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoadingProgress = false;
      });
    }
  }

  Future<void> _resetQuizAttempts(int studentId, String studentName) async {
    if (_selectedCourseId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Réinitialiser les tentatives'),
        content: Text(
          'Êtes-vous sûr de vouloir réinitialiser les tentatives de quiz pour "$studentName" ? '
          'L\'étudiant pourra repasser le quiz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Réinitialiser'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _courseService.resetStudentQuizAttempts(_selectedCourseId!, studentId);
      if (!mounted) return;
      
      // Recharger la progression après la réinitialisation
      await _loadProgress(_selectedCourseId!);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tentatives de quiz réinitialisées pour $studentName'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la réinitialisation: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _resetCourseProgress(int studentId, String studentName) async {
    if (_selectedCourseId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Réinitialiser la progression'),
        content: Text(
          'Êtes-vous sûr de vouloir réinitialiser la progression du cours pour "$studentName" ? '
          'Toutes les leçons complétées seront réinitialisées et l\'étudiant devra recommencer le cours.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Réinitialiser'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _courseService.resetStudentCourseProgress(_selectedCourseId!, studentId);
      if (!mounted) return;
      
      // Recharger la progression après la réinitialisation
      await _loadProgress(_selectedCourseId!);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Progression du cours réinitialisée pour $studentName'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la réinitialisation: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      appBar: AppBar(
        title: const Text('Suivi des étudiants'),
        centerTitle: true,
        actions: _selectedCourseId != null && isMobile
            ? [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _selectedCourseId = null;
                      _selectedCourseProgress = null;
                    });
                  },
                ),
              ]
            : null,
      ),
      body: _isLoadingCourses
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _courses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Erreur: $_error',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadCourses,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : isMobile
                  ? _buildMobileLayout()
                  : _buildDesktopLayout(),
    );
  }

  Widget _buildMobileLayout() {
    if (_selectedCourseId == null) {
      // Afficher la liste des cours
      return _buildCoursesList();
    } else {
      // Afficher les détails de progression
      return _buildProgressDetails();
    }
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Liste des cours
        Container(
          width: 250,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              right: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          child: _buildCoursesList(),
        ),
        // Détails de progression
        Expanded(
          child: _buildProgressDetails(),
        ),
      ],
    );
  }

  Widget _buildCoursesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          child: const Text(
            'Mes cours',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: _courses.isEmpty
              ? const Center(
                  child: Text('Aucun cours disponible'),
                )
              : ListView.builder(
                  itemCount: _courses.length,
                  itemBuilder: (context, index) {
                    final course = _courses[index];
                    final isSelected = _selectedCourseId == course.id;

                    return InkWell(
                      onTap: () => _loadProgress(course.id),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.blue.shade50
                              : Colors.white,
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey.shade200,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            if (course.imageUrl != null) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: SafeNetworkImage(
                                  imageUrl: SafeNetworkImage.normalizeImageUrl(course.imageUrl),
                                  height: 50,
                                  width: 50,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            Expanded(
                              child: Text(
                                course.title,
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? Colors.blue.shade700
                                      : Colors.black,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle,
                                color: Colors.blue,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildProgressDetails() {
    if (_selectedCourseId == null) {
      return const Center(
        child: Text(
          'Sélectionnez un cours pour voir la progression des étudiants',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (_isLoadingProgress) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_selectedCourseProgress == null) {
      return const Center(
        child: Text('Aucune donnée disponible'),
      );
    }

    if (_selectedCourseProgress!.isEmpty) {
      return const Center(
        child: Text(
          'Aucun étudiant inscrit à ce cours',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(
                color: Colors.grey.shade300,
              ),
            ),
          ),
          child: Row(
            children: [
              const Text(
                'Progression des étudiants',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${_selectedCourseProgress!.length} étudiant${_selectedCourseProgress!.length > 1 ? 's' : ''}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _selectedCourseProgress!.length,
            itemBuilder: (context, index) {
              final progress = _selectedCourseProgress![index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.blue.shade100,
                            child: Text(
                              progress.fullName.isNotEmpty
                                  ? progress.fullName[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  progress.fullName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  progress.email,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (progress.completed)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Terminé',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Progression',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                LinearProgressIndicator(
                                  value: progress.progress / 100,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    progress.progress == 100
                                        ? Colors.green
                                        : Colors.blue,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${progress.progress.toStringAsFixed(1)}%',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Boutons d'action
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, color: Colors.blue),
                            tooltip: 'Actions',
                            onSelected: (value) {
                              if (value == 'reset_quiz') {
                                _resetQuizAttempts(progress.studentId, progress.fullName);
                              } else if (value == 'reset_progress') {
                                _resetCourseProgress(progress.studentId, progress.fullName);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'reset_quiz',
                                child: Row(
                                  children: [
                                    Icon(Icons.quiz, size: 20, color: Colors.blue),
                                    SizedBox(width: 8),
                                    Text('Réinitialiser les tentatives de quiz'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'reset_progress',
                                child: Row(
                                  children: [
                                    Icon(Icons.restart_alt, size: 20, color: Colors.orange),
                                    SizedBox(width: 8),
                                    Text('Réinitialiser la progression du cours'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (progress.rating != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.star,
                                    color: Colors.orange.shade700,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    progress.rating!.toStringAsFixed(1),
                                    style: TextStyle(
                                      color: Colors.orange.shade700,
                                      fontWeight: FontWeight.bold,
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
              );
            },
          ),
        ),
      ],
    );
  }
}
