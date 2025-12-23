import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../models/student_course.dart';
import '../models/lesson.dart';
import '../services/course_service.dart';

class CourseReaderScreen extends StatefulWidget {
  final StudentCourse course;
  final int? initialLessonId;

  const CourseReaderScreen({
    super.key,
    required this.course,
    this.initialLessonId,
  });

  @override
  State<CourseReaderScreen> createState() => _CourseReaderScreenState();
}

class _CourseReaderScreenState extends State<CourseReaderScreen> {
  final CourseService _courseService = CourseService();
  final ScrollController _scrollController = ScrollController();
  List<Lesson> _lessons = [];
  Lesson? _currentLesson;
  int _currentLessonIndex = 0;
  bool _isLoading = true;
  String? _error;
  bool _sidebarOpen = false; // Fermé par défaut sur mobile
  Set<int> _completedLessons = {};

  @override
  void initState() {
    super.initState();
    _loadLessons();
    _loadCompletedLessons();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadLessons() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final lessons = await _courseService.getStudentCourseLessons(widget.course.id);
      if (!mounted) return;

      // Trier les leçons par orderIndex
      final sortedLessons = [...lessons]..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

      setState(() {
        _lessons = sortedLessons;
        _isLoading = false;
      });

      // Sélectionner la leçon initiale
      if (widget.initialLessonId != null) {
        final lessonIndex = sortedLessons.indexWhere((l) => l.id == widget.initialLessonId);
        if (lessonIndex >= 0) {
          _selectLesson(sortedLessons[lessonIndex], lessonIndex);
        } else {
          _selectLesson(sortedLessons[0], 0);
        }
      } else {
        _selectLesson(sortedLessons[0], 0);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCompletedLessons() async {
    try {
      final courses = await _courseService.getStudentCourses();
      if (!mounted) return;

      final course = courses.firstWhere(
        (c) => c.id == widget.course.id,
        orElse: () => widget.course,
      );

      if (course.progress > 0 && _lessons.isNotEmpty) {
        final totalLessons = _lessons.length;
        final completedCount = ((course.progress / 100) * totalLessons).round();
        final sortedLessons = [..._lessons]..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
        
        setState(() {
          _completedLessons = {
            for (int i = 0; i < completedCount && i < sortedLessons.length; i++)
              sortedLessons[i].id
          };
        });
      }
    } catch (e) {
      print('Could not load course progress: $e');
    }
  }

  void _selectLesson(Lesson lesson, int index) {
    if (!mounted) return;
    
    // Vérifier que l'index est valide
    if (index < 0 || index >= _lessons.length) return;
    
    // Vérifier que la leçon existe
    if (lesson.id != _lessons[index].id) {
      // Trouver l'index correct
      final correctIndex = _lessons.indexWhere((l) => l.id == lesson.id);
      if (correctIndex == -1) return;
      setState(() {
        _currentLesson = _lessons[correctIndex];
        _currentLessonIndex = correctIndex;
      });
    } else {
      setState(() {
        _currentLesson = lesson;
        _currentLessonIndex = index;
      });
    }
    
    // Scroll vers le haut du contenu après sélection
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _navigateToPreviousLesson() {
    if (_currentLessonIndex > 0) {
      _selectLesson(_lessons[_currentLessonIndex - 1], _currentLessonIndex - 1);
    }
  }

  void _navigateToNextLesson() {
    if (_currentLessonIndex < _lessons.length - 1) {
      _selectLesson(_lessons[_currentLessonIndex + 1], _currentLessonIndex + 1);
    }
  }

  bool _isLessonCompleted(int lessonId) {
    return _completedLessons.contains(lessonId);
  }

  void _toggleSidebar() {
    setState(() {
      _sidebarOpen = !_sidebarOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF0f0f0f) : Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Chargement du cours...',
                style: TextStyle(color: theme.colorScheme.secondary),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF0f0f0f) : Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
                const SizedBox(height: 16),
                Text(
                  'Erreur',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.colorScheme.secondary),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Retour au cours'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_lessons.isEmpty) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF0f0f0f) : Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.book_outlined, size: 64, color: theme.colorScheme.secondary),
                const SizedBox(height: 16),
                Text(
                  'Cours non trouvé',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Le cours demandé n\'existe pas ou n\'est plus disponible.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.colorScheme.secondary),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Retour aux cours'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0f0f0f) : Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(theme, isDark),
            // Content
            Expanded(
              child: Stack(
                children: [
                  // Main Content
                  Row(
                    children: [
                      // Sidebar (avec animation)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        width: _sidebarOpen ? 280 : 0,
                        child: _sidebarOpen
                            ? _buildSidebar(theme, isDark)
                            : const SizedBox.shrink(),
                      ),
                      // Main Content
                      Expanded(
                        child: _currentLesson != null
                            ? _buildLessonContent(theme, isDark)
                            : _buildNoLessonSelected(theme),
                      ),
                    ],
                  ),
                  // Overlay pour fermer la sidebar sur mobile
                  if (_sidebarOpen)
                    Positioned.fill(
                      child: GestureDetector(
                        onTap: _toggleSidebar,
                        child: Container(
                          color: Colors.black.withOpacity(0.3),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1a1a1a) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(context).pop(),
            color: isDark ? Colors.white : theme.colorScheme.primary,
            iconSize: 24,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.course.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : theme.colorScheme.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.course.description.isNotEmpty)
                  Text(
                    widget.course.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: Icon(_sidebarOpen ? Icons.close_rounded : Icons.menu_rounded),
              onPressed: _toggleSidebar,
              color: theme.colorScheme.primary,
              iconSize: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(ThemeData theme, bool isDark) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Sidebar Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Chapitres',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: _toggleSidebar,
                  iconSize: 22,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          // Lessons List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _lessons.length,
              itemBuilder: (context, index) {
                final lesson = _lessons[index];
                final isActive = _currentLesson?.id == lesson.id;
                final isCompleted = _isLessonCompleted(lesson.id);

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      // Sélectionner la leçon d'abord
                      _selectLesson(lesson, index);
                      
                      // Fermer la sidebar sur mobile après un court délai pour permettre la mise à jour
                      if (MediaQuery.of(context).size.width < 600) {
                        Future.delayed(const Duration(milliseconds: 100), () {
                          if (mounted) {
                            _toggleSidebar();
                          }
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.white.withOpacity(0.2)
                            : Colors.transparent,
                        border: Border(
                          left: BorderSide(
                            color: isActive ? Colors.white : Colors.transparent,
                            width: 4,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Lesson Number/Checkmark
                          SizedBox(
                            width: 36,
                            height: 36,
                            child: Container(
                              decoration: BoxDecoration(
                                color: isCompleted
                                    ? Colors.green
                                    : isActive
                                        ? Colors.white.withOpacity(0.3)
                                        : Colors.white.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: isCompleted
                                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                                    : FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          '${index + 1}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Lesson Title
                          Expanded(
                            child: Text(
                              lesson.title,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonContent(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Lesson Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1a1a1a) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.menu_book_rounded,
                      size: 24,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _currentLesson!.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : theme.colorScheme.primary,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Leçon ${_currentLessonIndex + 1}/${_lessons.length}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Lesson Content
          if (_currentLesson!.description != null &&
              _currentLesson!.description!.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1a1a1a) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border(
                  left: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 4,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRect(
                child: MarkdownBody(
                  data: _currentLesson!.description!,
                  styleSheet: MarkdownStyleSheet(
                    p: TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: isDark ? Colors.grey[300] : Colors.grey[800],
                    ),
                    h1: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : theme.colorScheme.primary,
                    ),
                    h2: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : theme.colorScheme.primary,
                    ),
                    h3: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : theme.colorScheme.primary,
                    ),
                    code: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                      backgroundColor: isDark ? const Color(0xFF0d1117) : Colors.grey[200],
                      color: isDark ? const Color(0xFFc9d1d9) : Colors.black87,
                    ),
                    codeblockDecoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0d1117) : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark ? const Color(0xFF30363d) : Colors.grey[300]!,
                      ),
                    ),
                    blockquote: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[700],
                      fontStyle: FontStyle.italic,
                    ),
                    listBullet: TextStyle(
                      color: theme.colorScheme.primary,
                    ),
                    tableHead: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : theme.colorScheme.primary,
                    ),
                    tableBody: TextStyle(
                      color: isDark ? Colors.grey[300] : Colors.grey[800],
                    ),
                    tableBorder: TableBorder.all(
                      color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                    ),
                    textAlign: WrapAlignment.start,
                    horizontalRuleDecoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                  shrinkWrap: true,
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1a1a1a) : Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  'Aucun contenu disponible pour cette leçon.',
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 32),
          // Navigation Buttons
          Row(
            children: [
              // Previous Button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _currentLessonIndex > 0 ? _navigateToPreviousLesson : null,
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text(
                    'Précédent',
                    style: TextStyle(fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFF2a2a2a) : Colors.grey[200],
                    foregroundColor: isDark ? Colors.white : Colors.black87,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Next Button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _currentLessonIndex < _lessons.length - 1
                      ? _navigateToNextLesson
                      : null,
                  icon: const Icon(Icons.arrow_forward, size: 18),
                  label: const Text(
                    'Suivant',
                    style: TextStyle(fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoLessonSelected(ThemeData theme) {
    return Center(
      child: Text(
        'Sélectionnez une leçon dans le menu latéral pour commencer.',
        style: TextStyle(
          color: theme.colorScheme.secondary,
          fontSize: 16,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

