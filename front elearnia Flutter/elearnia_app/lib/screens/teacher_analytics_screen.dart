import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/course_analytics.dart';
import '../services/course_service.dart';
import '../services/quiz_service.dart';
import '../services/progress_service.dart';
import '../models/quiz.dart';

// Modèles pour les statistiques étendues
class DashboardStats {
  final int totalStudents;
  final int activeCourses;
  final int totalQuizzes;
  final double averageRating;
  final int totalEnrollments;
  final int completedCourses;
  final double averageProgress;

  DashboardStats({
    required this.totalStudents,
    required this.activeCourses,
    required this.totalQuizzes,
    required this.averageRating,
    required this.totalEnrollments,
    required this.completedCourses,
    required this.averageProgress,
  });
}

class CourseStats {
  final TeacherCourse course;
  final int enrollments;
  final double averageProgress;
  final int completed;
  final double averageRating;

  CourseStats({
    required this.course,
    required this.enrollments,
    required this.averageProgress,
    required this.completed,
    required this.averageRating,
  });
}

class QuizStats {
  final Quiz quiz;
  final int totalAttempts;
  final double averageScore;
  final int passed;
  final int failed;

  QuizStats({
    required this.quiz,
    required this.totalAttempts,
    required this.averageScore,
    required this.passed,
    required this.failed,
  });
}

class TeacherAnalyticsScreen extends StatefulWidget {
  final User user;

  const TeacherAnalyticsScreen({super.key, required this.user});

  @override
  State<TeacherAnalyticsScreen> createState() => _TeacherAnalyticsScreenState();
}

class _TeacherAnalyticsScreenState extends State<TeacherAnalyticsScreen> {
  final CourseService _courseService = CourseService();
  final QuizService _quizService = QuizService();
  final ProgressService _progressService = ProgressService();

  CourseAnalytics? _analytics;
  DashboardStats? _dashboardStats;
  List<TeacherCourse> _courses = [];
  List<Quiz> _quizzes = [];
  List<CourseStats> _courseStats = [];
  List<QuizStats> _quizStats = [];
  List<StudentProgress> _allStudentProgress = [];
  
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Charger toutes les données en parallèle
      final analytics = await _courseService.getAnalytics();
      final courses = await _courseService.getMyTeacherCourses();
      final quizzes = await _quizService.getTeacherQuizzes();
      final quizScores = await _quizService.getAllQuizzesScores();

      if (!mounted) return;

      setState(() {
        _analytics = analytics;
        _courses = courses;
        _quizzes = quizzes;
      });

      // Calculer les statistiques du dashboard
      await _calculateDashboardStats(courses, quizzes, quizScores);
      
      // Charger les statistiques détaillées par cours
      await _loadCourseStats(courses);
      
      // Charger les statistiques des quizzes
      _loadQuizStats(quizzes, quizScores);

      if (!mounted) return;
      setState(() {
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

  Future<void> _calculateDashboardStats(
    List<TeacherCourse> courses,
    List<Quiz> quizzes,
    List<Map<String, dynamic>> quizScores,
  ) async {
    final totalStudents = _analytics?.totalStudents ?? 0;
    final activeCourses = courses.length;
    final totalQuizzes = quizzes.length;
    final averageRating = _analytics?.avgRating ?? 0.0;

    // Charger toutes les progressions
    List<StudentProgress> allStudents = [];
    int totalEnrollments = 0;
    int completedCourses = 0;
    double totalProgress = 0;
    int progressCount = 0;

    for (var course in courses) {
      try {
        final progress = await _progressService.getStudentsProgress(course.id);
        totalEnrollments += progress.length;
        for (var p in progress) {
          if (p.completed) completedCourses++;
          totalProgress += p.progress;
          progressCount++;
          allStudents.add(p);
        }
      } catch (e) {
        // Ignorer les erreurs pour un cours spécifique
      }
    }

    final averageProgress = progressCount > 0 ? totalProgress / progressCount : 0.0;

    if (!mounted) return;
    setState(() {
      _allStudentProgress = allStudents;
      _dashboardStats = DashboardStats(
        totalStudents: totalStudents,
        activeCourses: activeCourses,
        totalQuizzes: totalQuizzes,
        averageRating: averageRating,
        totalEnrollments: totalEnrollments,
        completedCourses: completedCourses,
        averageProgress: averageProgress,
      );
    });
  }

  Future<void> _loadCourseStats(List<TeacherCourse> courses) async {
    List<CourseStats> stats = [];

    for (var course in courses) {
      try {
        final progress = await _progressService.getStudentsProgress(course.id);
        final enrollments = progress.length;
        final completed = progress.where((p) => p.completed).length;
        final totalProgress = progress.fold(0.0, (sum, p) => sum + p.progress);
        final averageProgress = enrollments > 0 ? totalProgress / enrollments : 0.0;
        final ratedProgress = progress.where((p) => p.rating != null).toList();
        final totalRating = ratedProgress.fold(0.0, (sum, p) => sum + (p.rating ?? 0));
        final averageRating = ratedProgress.isNotEmpty ? totalRating / ratedProgress.length : 0.0;

        stats.add(CourseStats(
          course: course,
          enrollments: enrollments,
          averageProgress: averageProgress,
          completed: completed,
          averageRating: averageRating,
        ));
      } catch (e) {
        // Ajouter le cours avec des stats à zéro en cas d'erreur
        stats.add(CourseStats(
          course: course,
          enrollments: 0,
          averageProgress: 0.0,
          completed: 0,
          averageRating: 0.0,
        ));
      }
    }

    if (!mounted) return;
    setState(() {
      _courseStats = stats;
    });
  }

  void _loadQuizStats(List<Quiz> quizzes, List<Map<String, dynamic>> quizScores) {
    List<QuizStats> stats = [];

    for (var quiz in quizzes) {
      final quizScoreData = quizScores.firstWhere(
        (qs) => qs['quizId'] == quiz.id,
        orElse: () => <String, dynamic>{},
      );

      if (quizScoreData.isNotEmpty) {
        final scores = (quizScoreData['scores'] as List<dynamic>?) ?? [];
        final totalAttempts = scores.length;
        final totalScore = scores.fold<double>(
          0.0,
          (sum, s) {
            final scoreValue = (s as Map<String, dynamic>)['score'];
            if (scoreValue == null) return sum;
            final scoreNum = scoreValue is num ? scoreValue.toDouble() : 0.0;
            return sum + scoreNum;
          },
        );
        final averageScore = totalAttempts > 0 ? totalScore / totalAttempts : 0.0;
        final passed = scores.where((s) => (s as Map<String, dynamic>)['passed'] == true).length;
        final failed = totalAttempts - passed;

        stats.add(QuizStats(
          quiz: quiz,
          totalAttempts: totalAttempts,
          averageScore: averageScore,
          passed: passed,
          failed: failed,
        ));
      } else {
        stats.add(QuizStats(
          quiz: quiz,
          totalAttempts: 0,
          averageScore: 0.0,
          passed: 0,
          failed: 0,
        ));
      }
    }

    setState(() {
      _quizStats = stats;
    });
  }

  List<CourseStats> _getTopCourses({int limit = 5}) {
    final sorted = List<CourseStats>.from(_courseStats)
      ..sort((a, b) => b.enrollments.compareTo(a.enrollments));
    return sorted.take(limit).toList();
  }

  List<QuizStats> _getTopQuizzes({int limit = 5}) {
    final sorted = List<QuizStats>.from(_quizStats)
      ..sort((a, b) => b.totalAttempts.compareTo(a.totalAttempts));
    return sorted.take(limit).toList();
  }

  List<Map<String, dynamic>> _getStudentsByProgress() {
    final completed = _allStudentProgress.where((s) => s.completed).length;
    final inProgress = _allStudentProgress.where((s) => !s.completed && s.progress > 0).length;
    final notStarted = _allStudentProgress.where((s) => !s.completed && s.progress == 0).length;

    return [
      {'label': 'Terminés', 'count': completed, 'color': const Color(0xFF10B981)},
      {'label': 'En cours', 'count': inProgress, 'color': const Color(0xFFF59E0B)},
      {'label': 'Non commencés', 'count': notStarted, 'color': const Color(0xFF9CA3AF)},
    ];
  }

  Color _getProgressColor(double progress) {
    if (progress >= 80) return const Color(0xFF10B981);
    if (progress >= 50) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  String _formatNumber(double value) {
    return value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: primaryColor,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primaryColor,
                      primaryColor.withValues(alpha: 0.85),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Analyses',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                          onPressed: _loadDashboardData,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _isLoading
                ? SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: const Center(child: CircularProgressIndicator()),
                  )
                : _error != null
                    ? _buildErrorWidget(primaryColor, theme)
                    : _buildContent(theme, primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme, Color primaryColor) {
    if (_dashboardStats == null) {
      return const Center(child: Text('Aucune donnée disponible'));
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ================= KPIs =================
          _buildKPIs(theme),
          const SizedBox(height: 24),

          // ================= Graphiques =================
          _buildChartsSection(theme),
          const SizedBox(height: 24),

          // ================= Statistiques par cours =================
          _buildCourseStatsSection(theme),
          const SizedBox(height: 24),

          // ================= Statistiques des quizzes =================
          _buildQuizStatsSection(theme),
          const SizedBox(height: 24),

          // ================= Top 5 quizzes =================
          _buildTopQuizzesSection(theme),
        ],
      ),
    );
  }

  Widget _buildKPIs(ThemeData theme) {
    final stats = _dashboardStats!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vue d\'ensemble',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildKPICard(
              theme,
              Icons.people_rounded,
              'Étudiants totaux',
              '${stats.totalStudents}',
              const Color(0xFF3B82F6),
            ),
            _buildKPICard(
              theme,
              Icons.menu_book_rounded,
              'Cours actifs',
              '${stats.activeCourses}',
              const Color(0xFF10B981),
            ),
            _buildKPICard(
              theme,
              Icons.quiz_rounded,
              'Quizzes créés',
              '${stats.totalQuizzes}',
              const Color(0xFF8B5CF6),
            ),
            _buildKPICard(
              theme,
              Icons.star_rounded,
              'Note moyenne',
              stats.averageRating > 0 ? _formatNumber(stats.averageRating) : '0.0',
              const Color(0xFFF59E0B),
            ),
            _buildKPICard(
              theme,
              Icons.trending_up_rounded,
              'Progression moyenne',
              '${_formatNumber(stats.averageProgress)}%',
              const Color(0xFF06B6D4),
            ),
            _buildKPICard(
              theme,
              Icons.check_circle_rounded,
              'Cours complétés',
              '${stats.completedCourses}',
              const Color(0xFF10B981),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKPICard(ThemeData theme, IconData icon, String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.secondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Répartition des étudiants
        _buildStudentDistributionCard(theme),
        const SizedBox(height: 16),
        // Top 5 cours
        _buildTopCoursesCard(theme),
      ],
    );
  }

  Widget _buildStudentDistributionCard(ThemeData theme) {
    final distribution = _getStudentsByProgress();
    final total = _allStudentProgress.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Répartition des étudiants',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          ...distribution.map((item) {
            final count = item['count'] as int;
            final label = item['label'] as String;
            final color = item['color'] as Color;
            final percentage = total > 0 ? (count / total) * 100 : 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      minHeight: 8,
                      backgroundColor: theme.dividerColor,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTopCoursesCard(ThemeData theme) {
    final topCourses = _getTopCourses(limit: 5);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top 5 cours populaires',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          if (topCourses.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Aucun cours avec des inscriptions',
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.secondary,
                ),
              ),
            )
          else
            ...topCourses.map((stat) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stat.course.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${stat.enrollments} inscriptions',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMiniStat(
                              theme,
                              'Progression',
                              '${_formatNumber(stat.averageProgress)}%',
                            ),
                          ),
                          Expanded(
                            child: _buildMiniStat(
                              theme,
                              'Complétés',
                              '${stat.completed}',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildMiniStat(ThemeData theme, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: theme.colorScheme.secondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildCourseStatsSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Statistiques par cours',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_courseStats.length} cours',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_courseStats.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Aucune statistique disponible',
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.secondary,
                ),
              ),
            )
          else
            ..._courseStats.map((stat) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.dividerColor,
                    width: 1,
                  ),
                ),
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
                                stat.course.title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: stat.course.published
                                      ? Colors.green.withValues(alpha: 0.1)
                                      : Colors.grey.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  stat.course.published ? 'Publié' : 'Brouillon',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: stat.course.published ? Colors.green : Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatItem(theme, 'Inscriptions', '${stat.enrollments}'),
                        ),
                        Expanded(
                          child: _buildStatItem(
                            theme,
                            'Progression',
                            '${_formatNumber(stat.averageProgress)}%',
                            color: _getProgressColor(stat.averageProgress),
                          ),
                        ),
                        Expanded(
                          child: _buildStatItem(theme, 'Complétés', '${stat.completed}'),
                        ),
                        Expanded(
                          child: _buildStatItem(
                            theme,
                            'Note',
                            stat.averageRating > 0
                                ? _formatNumber(stat.averageRating)
                                : 'N/A',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildStatItem(ThemeData theme, String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: theme.colorScheme.secondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color ?? theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildQuizStatsSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Statistiques des quizzes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_quizStats.length} quizzes',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_quizStats.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Aucun quiz créé',
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.secondary,
                ),
              ),
            )
          else
            ..._quizStats.map((stat) {
              final successRate = stat.totalAttempts > 0
                  ? (stat.passed / stat.totalAttempts) * 100
                  : 0.0;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.dividerColor,
                    width: 1,
                  ),
                ),
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
                                stat.quiz.title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              if (stat.quiz.description.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  stat.quiz.description.length > 50
                                      ? '${stat.quiz.description.substring(0, 50)}...'
                                      : stat.quiz.description,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme.colorScheme.secondary,
                                  ),
                                  maxLines: 2,
                                ),
                              ],
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: stat.quiz.courseId != null
                                ? Colors.blue.withValues(alpha: 0.1)
                                : Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            stat.quiz.courseId != null ? 'Cours' : 'Standalone',
                            style: TextStyle(
                              fontSize: 10,
                              color: stat.quiz.courseId != null ? Colors.blue : Colors.orange,
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
                          child: _buildStatItem(theme, 'Tentatives', '${stat.totalAttempts}'),
                        ),
                        Expanded(
                          child: _buildStatItem(
                            theme,
                            'Score moyen',
                            stat.totalAttempts > 0
                                ? '${_formatNumber(stat.averageScore)}%'
                                : 'N/A',
                            color: stat.totalAttempts > 0
                                ? _getProgressColor(stat.averageScore)
                                : null,
                          ),
                        ),
                        Expanded(
                          child: _buildStatItem(theme, 'Réussis', '${stat.passed}'),
                        ),
                        Expanded(
                          child: _buildStatItem(theme, 'Échoués', '${stat.failed}'),
                        ),
                        Expanded(
                          child: _buildStatItem(
                            theme,
                            'Taux',
                            stat.totalAttempts > 0
                                ? '${_formatNumber(successRate)}%'
                                : 'N/A',
                            color: stat.totalAttempts > 0
                                ? _getProgressColor(successRate)
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildTopQuizzesSection(ThemeData theme) {
    final topQuizzes = _getTopQuizzes(limit: 5);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top 5 quizzes les plus tentés',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          if (topQuizzes.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Aucun quiz avec des tentatives',
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.secondary,
                ),
              ),
            )
          else
            ...topQuizzes.map((stat) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stat.quiz.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${stat.totalAttempts} tentatives',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMiniStat(
                              theme,
                              'Score moyen',
                              stat.totalAttempts > 0
                                  ? '${_formatNumber(stat.averageScore)}%'
                                  : '0.0%',
                            ),
                          ),
                          Expanded(
                            child: _buildMiniStat(
                              theme,
                              'Réussis',
                              '${stat.passed}',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(Color primaryColor, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.error_outline_rounded,
                size: 64, color: Colors.red),
          ),
          const SizedBox(height: 24),
          Text(
            'Erreur',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _loadDashboardData,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}
