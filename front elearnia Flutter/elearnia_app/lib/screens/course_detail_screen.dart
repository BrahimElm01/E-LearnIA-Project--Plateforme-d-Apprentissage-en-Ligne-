import 'package:flutter/material.dart';

import '../models/student_course.dart';
import '../models/lesson.dart';
import '../models/review.dart';
import '../services/course_service.dart';
import '../services/quiz_service.dart';
import '../services/review_service.dart';
import '../widgets/safe_network_image.dart';
import 'lesson_player_screen.dart';
import 'quiz_screen.dart';
import 'course_reader_screen.dart';

class CourseDetailScreen extends StatefulWidget {
  final StudentCourse course;

  const CourseDetailScreen({
    super.key,
    required this.course,
  });

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  final CourseService _courseService = CourseService();
  final QuizService _quizService = QuizService();
  final ReviewService _reviewService = ReviewService();
  List<Lesson> _lessons = [];
  Set<int> _completedLessonIds = {}; // IDs des leçons complétées
  List<Review> _reviews = [];
  bool _isLoading = true;
  bool _isLoadingReviews = false;
  String? _error;
  bool _isNotEnrolled = false;
  bool _hasQuiz = false;

  @override
  void initState() {
    super.initState();
    _loadLessons(); // _checkQuiz() sera appelé dans _loadLessons() si l'étudiant est inscrit
    _loadReviews();
    // Initialiser les leçons complétées basées sur la progression
    _updateCompletedLessons();
  }

  Future<void> _checkQuiz() async {
    // Ne vérifier le quiz que si l'étudiant est inscrit
    if (_isNotEnrolled) {
      setState(() {
        _hasQuiz = false;
      });
      return;
    }

    try {
      await _quizService.getQuizByCourse(widget.course.id);
      if (!mounted) return;
      // Si on a réussi à récupérer le quiz, il existe
      setState(() {
        _hasQuiz = true;
      });
      // Debug
      print('Quiz trouvé pour le cours ${widget.course.id}, _hasQuiz = true');
      print('Progression du cours: ${widget.course.progress}%');
      print('Cours complété: ${widget.course.completed}');
      print('Nombre de leçons: ${_lessons.length}');
    } catch (e) {
      // Vérifier si c'est une erreur d'inscription ou si le quiz n'existe pas
      final errorMessage = e.toString();
      final isNotEnrolled = errorMessage.contains('inscrit') || 
                            errorMessage.contains('not enrolled');
      final isNotFound = errorMessage.contains('404') || 
                         errorMessage.contains('Aucun quiz');
      
      if (!mounted) return;
      setState(() {
        // Si l'étudiant n'est pas inscrit ou si le quiz n'existe pas (404), pas de quiz
        _hasQuiz = false;
      });
      
      // Debug: afficher l'erreur
      print('Erreur lors de la vérification du quiz pour le cours ${widget.course.id}: $errorMessage');
      print('isNotEnrolled: $isNotEnrolled, isNotFound: $isNotFound');
    }
  }

  bool _allLessonsCompleted() {
    // Vérifier si toutes les leçons sont complétées
    // Si le cours est marqué comme complété, c'est bon
    if (widget.course.completed) return true;
    
    // Si on a des leçons chargées, vérifier la progression
    if (_lessons.isNotEmpty) {
      // Si la progression est >= 90%, on considère que toutes les leçons sont complétées
      // (on utilise 90% pour être plus permissif)
      return widget.course.progress >= 90;
    }
    
    // Sinon, vérifier la progression du cours passé en paramètre
    return widget.course.progress >= 90;
  }

  Future<void> _loadReviews() async {
    if (!mounted) return;
    setState(() {
      _isLoadingReviews = true;
    });
    try {
      final reviews = await _reviewService.getApprovedReviews(widget.course.id);
      if (!mounted) return;
      setState(() {
        _reviews = reviews;
        _isLoadingReviews = false;
      });
      // Debug: afficher le nombre de reviews chargés
      print('Reviews chargés: ${reviews.length}');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingReviews = false;
        // En cas d'erreur, initialiser avec une liste vide plutôt que de laisser null
        _reviews = [];
      });
      // Ne pas afficher d'erreur si les reviews ne peuvent pas être chargés
      print('Erreur chargement reviews: $e');
    }
  }

  void _updateCompletedLessons() {
    // Mettre à jour les leçons complétées basées sur la progression
    // Mais préserver les IDs déjà marqués comme complétées
    if (_lessons.isEmpty) return;
    
    final Set<int> newCompletedIds = Set.from(_completedLessonIds); // Préserver les IDs existants
    
    // Si la progression est à 100%, toutes les leçons sont complétées
    if (widget.course.progress >= 100) {
      newCompletedIds.addAll(_lessons.map((l) => l.id));
    } else {
      // Calculer combien de leçons sont complétées basées sur la progression
      final progressPercentage = widget.course.progress / 100;
      final completedCount = (progressPercentage * _lessons.length).round();
      // Ajouter les premières leçons jusqu'au nombre calculé
      newCompletedIds.addAll(_lessons.take(completedCount).map((l) => l.id));
    }
    
    // Ne mettre à jour que si nécessaire pour éviter les rebuilds inutiles
    if (newCompletedIds.length != _completedLessonIds.length || 
        !newCompletedIds.containsAll(_completedLessonIds)) {
      setState(() {
        _completedLessonIds = newCompletedIds;
      });
    }
  }

  Future<void> _openQuiz() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => QuizScreen(
          courseId: widget.course.id,
          course: widget.course,
        ),
      ),
    );

    // Si le quiz est réussi et le cours complété, recharger les données
    if (result == true) {
      // Recharger les données du cours si nécessaire
      await _loadLessons();
      if (!mounted) return;
      // Retourner true pour indiquer que le cours a été complété
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _loadLessons() async {
    try {
      final lessons = await _courseService.getStudentCourseLessons(widget.course.id);
      if (!mounted) return;
      setState(() {
        _lessons = lessons;
        _isLoading = false;
        _error = null;
        _isNotEnrolled = false;
      });
      // Si l'étudiant est inscrit, vérifier le quiz
      await _checkQuiz();
      // Mettre à jour les leçons complétées basées sur la progression
      // Mais ne pas supprimer les IDs déjà présents
      _updateCompletedLessons();
    } catch (e) {
      if (!mounted) return;
      final errorMessage = e.toString();
      // Vérifier si l'erreur indique que l'étudiant n'est pas inscrit
      final isNotEnrolled = errorMessage.contains('inscrit') || 
                            errorMessage.contains('not enrolled');
      setState(() {
        _error = isNotEnrolled ? null : errorMessage;
        _isNotEnrolled = isNotEnrolled;
        _isLoading = false;
      });
      // Si l'étudiant n'est pas inscrit, pas besoin de vérifier le quiz
      if (isNotEnrolled) {
        setState(() {
          _hasQuiz = false;
        });
      }
    }
  }

  Future<void> _enrollToCourse() async {
    setState(() => _isLoading = true);
    try {
      await _courseService.enrollToCourse(widget.course.id);
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inscription réussie ! 🎉'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Recharger les leçons après l'inscription
      await _loadLessons();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'inscription : $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _onLessonTap(int index) async {
    final lesson = _lessons[index];

    final completed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => LessonPlayerScreen(
          courseId: widget.course.id,
          lessonId: lesson.id,
          lessonIndex: index, // Passer l'index réel de la leçon
          courseTitle: widget.course.title,
          lessonTitle: lesson.title,
          duration: lesson.duration != null ? '${lesson.duration} min' : 'N/A',
          videoUrl: lesson.videoUrl,
          description: lesson.description,
          totalLessons: _lessons.length,
        ),
      ),
    );

    // Si la leçon a été complétée, ajouter son ID à la liste des complétées
    if (completed == true) {
      setState(() {
        _completedLessonIds.add(lesson.id);
      });
      // Recharger les leçons pour mettre à jour la progression
      await _loadLessons();
      // Recharger aussi les reviews au cas où un review a été approuvé
      await _loadReviews();
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              _loadLessons(),
              _loadReviews(),
            ]);
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(theme.colorScheme.primary),
                const SizedBox(height: 16),

              // carte principale
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildMainInfoCard(),
              ),
              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildRequirementsSection(),
              ),
              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildWhatYouWillLearnSection(),
              ),
              const SizedBox(height: 24),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildCourseContentSection(),
              ),
              const SizedBox(height: 24),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildReviewsSection(),
              ),
              const SizedBox(height: 24),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      if (_lessons.isNotEmpty) {
                        _onLessonTap(0);
                      }
                    },
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text(
                      'Start Learning',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------
  // HEADER
  // -------------------------------------------------------------------
  Widget _buildHeader(Color primaryBlack) {
    return Stack(
      children: [
        Container(
          height: 220,
          width: double.infinity,
          decoration: BoxDecoration(
            color: primaryBlack,
          ),
          child: SafeNetworkImage(
            imageUrl: widget.course.imageUrl,
            width: double.infinity,
            height: 220,
            fit: BoxFit.cover,
            backgroundColor: primaryBlack,
            errorWidget: const Center(
              child: Icon(
                Icons.play_circle_fill_rounded,
                color: Colors.white,
                size: 64,
              ),
            ),
            placeholder: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
        ),
        Positioned(
          top: 12,
          left: 8,
          right: 8,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _roundIconButton(
                icon: Icons.arrow_back_rounded,
                onTap: () => Navigator.of(context).pop(),
              ),
              _roundIconButton(
                icon: Icons.filter_list_rounded,
                onTap: () {},
              ),
            ],
          ),
        ),
        const Positioned(
          left: 16,
          bottom: 16,
          child: Text(
            'All Courses',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------
  // MAIN CARD
  // -------------------------------------------------------------------
  Widget _buildMainInfoCard() {
    final course = widget.course;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            course.title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            course.description,
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
              const SizedBox(width: 4),
              Text(
                '4.8 (245 reviews)',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              _InfoChip(
                icon: Icons.people_alt_rounded,
                labelTop: '1200+',
                labelBottom: 'Students',
              ),
              _InfoChip(
                icon: Icons.play_lesson_rounded,
                labelTop: '6',
                labelBottom: 'Lessons',
              ),
              _InfoChip(
                icon: Icons.bar_chart_rounded,
                labelTop: 'Intermediate',
                labelBottom: 'Level',
              ),
            ],
          ),
          // Bouton "Lire le cours" si l'étudiant est inscrit
          if (!_isNotEnrolled && _lessons.isNotEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CourseReaderScreen(
                        course: widget.course,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.menu_book_rounded),
                label: const Text('Lire le cours'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRequirementsSection() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Requirements',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.primary,
          ),
        ),
        SizedBox(height: 8),
        _BulletPoint(text: 'Basic programming knowledge'),
        _BulletPoint(text: 'Computer with internet connection'),
        _BulletPoint(text: 'Dedication to learn'),
      ],
    );
  }

  Widget _buildWhatYouWillLearnSection() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "What you'll learn",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.primary,
          ),
        ),
        SizedBox(height: 8),
        _CheckPoint(text: 'Build beautiful native apps'),
        _CheckPoint(text: 'Master Dart programming'),
        _CheckPoint(text: 'State management'),
        _CheckPoint(text: 'REST API integration'),
        _CheckPoint(text: 'Local data storage'),
      ],
    );
  }

  Widget _buildCourseContentSection() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Course Content',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_isNotEnrolled)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const Icon(
                    Icons.lock_outline,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Vous n\'êtes pas inscrit à ce cours',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Inscrivez-vous pour accéder aux vidéos',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.secondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _enrollToCourse,
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('S\'inscrire au cours'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else if (_error != null)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
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
            ),
          )
        else if (_lessons.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Text('Aucune leçon disponible pour ce cours.'),
            ),
          )
        else
          Column(
            children: [
              ListView.separated(
                itemCount: _lessons.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final lesson = _lessons[index];

                  return InkWell(
                    onTap: () => _onLessonTap(index),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.3 : 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: _completedLessonIds.contains(lesson.id)
                                    ? Colors.green.shade100
                                    : Theme.of(context).brightness == Brightness.dark
                                        ? Colors.grey.shade800
                                        : Colors.grey.shade200,
                                child: Icon(
                                  Icons.play_arrow_rounded,
                                  color: _completedLessonIds.contains(lesson.id)
                                      ? Colors.green.shade700
                                      : Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              if (_completedLessonIds.contains(lesson.id))
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lesson.title,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _completedLessonIds.contains(lesson.id)
                                        ? Colors.green.shade700
                                        : Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  lesson.duration != null
                                      ? '${lesson.duration} min'
                                      : 'Durée non spécifiée',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).colorScheme.secondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Afficher l'icône de vérification verte si la leçon est complétée
                          if (_completedLessonIds.contains(lesson.id))
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Icon(
                                Icons.check_circle,
                                color: Colors.green.shade600,
                                size: 26,
                              ),
                            ),
                          const Icon(Icons.chevron_right_rounded),
                        ],
                      ),
                    ),
                  );
                },
              ),
              // Bouton Quiz (affiché seulement si toutes les leçons sont complétées et qu'un quiz existe)
              // Afficher le quiz si : un quiz existe ET (toutes les leçons sont complétées OU progression >= 50% OU il y a des leçons)
              // On affiche le quiz même si le cours n'est pas encore marqué comme complété
              // (le quiz permet de compléter le cours)
              if (_hasQuiz && (_allLessonsCompleted() || widget.course.progress >= 50 || _lessons.isNotEmpty)) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.black,
                        Colors.black.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.quiz_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Quiz final',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Passez le quiz pour terminer le cours',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _openQuiz,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.play_arrow_rounded),
                              SizedBox(width: 8),
                              Text(
                                'Passer le quiz',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
      ],
    );
  }

  Widget _buildReviewsSection() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Reviews',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
                    if (!_isNotEnrolled)
                      TextButton.icon(
                        onPressed: _showAddReviewDialog,
                        icon: const Icon(Icons.add_circle_outline, size: 18),
                        label: const Text('Ajouter un avis'),
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.primary,
                        ),
                      ),
          ],
        ),
        const SizedBox(height: 8),
        if (_isLoadingReviews)
          const Center(child: CircularProgressIndicator())
        else if (_reviews.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text(
                'Aucun avis pour le moment',
                style: TextStyle(color: theme.colorScheme.secondary),
              ),
            ),
          )
        else
          ..._reviews.map((review) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ReviewCard(
                  userInitial: review.studentName.isNotEmpty
                      ? review.studentName[0].toUpperCase()
                      : 'U',
                  userName: review.studentName,
                  daysAgo: _formatDate(review.createdAt),
                  rating: review.rating,
                  text: review.comment,
                ),
              )),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return "Aujourd'hui";
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} jours';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return weeks == 1 ? '1 semaine' : '$weeks semaines';
    } else {
      final months = (difference.inDays / 30).floor();
      return months == 1 ? '1 mois' : '$months mois';
    }
  }

  Future<void> _showAddReviewDialog() async {
    final ratingController = ValueNotifier<int>(5);
    final commentController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Ajouter un avis'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Note:'),
                  const SizedBox(height: 8),
                  ValueListenableBuilder<int>(
                    valueListenable: ratingController,
                    builder: (context, rating, _) => Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          icon: Icon(
                            index < rating
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: Colors.amber,
                            size: 32,
                          ),
                          onPressed: () {
                            ratingController.value = index + 1;
                          },
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: commentController,
                    decoration: const InputDecoration(
                      labelText: 'Commentaire (optionnel)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting
                  ? null
                  : () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      setDialogState(() {
                        isSubmitting = true;
                      });

                      try {
                        await _reviewService.addReview(
                          courseId: widget.course.id,
                          rating: ratingController.value,
                          comment: commentController.text.trim().isEmpty
                              ? null
                              : commentController.text.trim(),
                        );

                        if (!mounted) return;
                        Navigator.of(context).pop();
                        if (!mounted) return;
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Votre avis a été soumis et est en attente d\'approbation'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        // Ne plus bloquer l'ajout de plusieurs reviews
                        // setState(() {
                        //   _hasUserReview = true;
                        // });
                        // Recharger les reviews après un court délai pour permettre au backend de traiter
                        await Future.delayed(const Duration(milliseconds: 500));
                        if (mounted) {
                          _loadReviews();
                        }
                      } catch (e) {
                        if (!mounted) return;
                        setDialogState(() {
                          isSubmitting = false;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Erreur: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Envoyer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roundIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

// =====================================================================
//  PETITS WIDGETS RÉUTILISABLES
// =====================================================================

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String labelTop;
  final String labelBottom;

  const _InfoChip({
    required this.icon,
    required this.labelTop,
    required this.labelBottom,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, size: 22, color: theme.colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          labelTop,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          labelBottom,
          style: TextStyle(
            fontSize: 11,
            color: theme.colorScheme.secondary,
          ),
        ),
      ],
    );
  }
}

class _BulletPoint extends StatelessWidget {
  final String text;

  const _BulletPoint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  '),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckPoint extends StatelessWidget {
  final String text;

  const _CheckPoint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 16,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final String userInitial;
  final String userName;
  final String daysAgo;
  final int rating;
  final String text;

  const _ReviewCard({
    required this.userInitial,
    required this.userName,
    required this.daysAgo,
    this.rating = 5,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: theme.colorScheme.primary,
            child: Text(
              userInitial,
              style: TextStyle(color: theme.colorScheme.onPrimary),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        userName,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    Text(
                      daysAgo,
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: List.generate(
                    5,
                    (index) => Icon(
                      index < rating
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      size: 14,
                      color: Colors.amber,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}