import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/auth_service.dart';

import 'login_screen.dart';
import 'teacher_courses_screen.dart';
import 'teacher_analytics_screen.dart';
import 'student_progress_screen.dart';
import 'profile_screen.dart';
import 'create_course_screen.dart';
import 'create_standalone_quiz_screen.dart';
import 'quiz_scores_screen.dart';
import 'ai_course_generator_screen.dart';
import 'generate_quiz_ai_screen.dart';
import 'teacher_quizzes_screen.dart';

class TeacherHomeScreen extends StatefulWidget {
  final User user;

  const TeacherHomeScreen({
    super.key,
    required this.user,
  });

  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  final AuthService _authService = AuthService();

  int _currentIndex = 0;
  bool _isLoggingOut = false;

  Future<void> _logout() async {
    if (_isLoggingOut) return;

    setState(() => _isLoggingOut = true);

    try {
      // on efface le token (alias vers logout())
      await _authService.clearToken();
    } finally {
      if (!mounted) {
        _isLoggingOut = false;
        return;
      }

      setState(() => _isLoggingOut = false);

      // on revient vers l'écran de login
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = theme.scaffoldBackgroundColor;
    final primary = theme.colorScheme.primary;

    final pages = <Widget>[
      _DashboardTab(user: widget.user),
      TeacherCoursesScreen(user: widget.user),
      TeacherAnalyticsScreen(user: widget.user),
      ProfileScreen(
        user: widget.user,
        isTeacher: true,
        onLogout: _logout,
      ),
    ];

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: pages,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: primary,
        unselectedItemColor: theme.colorScheme.secondary,
        backgroundColor: theme.cardColor,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Tableau de bord',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_rounded),
            label: 'Mes cours',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_rounded),
            label: 'Analyses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 1
          ? FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const CreateCourseScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      )
          : null,
    );
  }
}

/// Onglet "Dashboard" pour le prof
class _DashboardTab extends StatelessWidget {
  final User user;

  const _DashboardTab({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = theme.scaffoldBackgroundColor;
    final primaryColor = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: background,
      body: CustomScrollView(
        slivers: [
          // Header avec gradient
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: primaryColor,
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Bonjour,',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          user.fullName,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Contenu
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.flash_on_rounded,
                          color: primaryColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Actions rapides',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _DashboardCard(
                    icon: Icons.auto_awesome_rounded,
                    title: 'Enseigner avec IA',
                    subtitle: 'Génère automatiquement un cours complet avec IA',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AICourseGeneratorScreen(user: user),
                        ),
                      );
                    },
                  ),
                  _DashboardCard(
                    icon: Icons.add_circle_outline_rounded,
                    title: 'Créer un cours',
                    subtitle: 'Ajoute un nouveau cours pour tes élèves',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const CreateCourseScreen(),
                        ),
                      );
                    },
                  ),
                  _DashboardCard(
                    icon: Icons.menu_book_rounded,
                    title: 'Mes cours',
                    subtitle: 'Voir et gérer tous tes cours',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => TeacherCoursesScreen(user: user),
                        ),
                      );
                    },
                  ),
                  _DashboardCard(
                    icon: Icons.bar_chart_rounded,
                    title: 'Analyses',
                    subtitle: 'Statistiques et performances des cours',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => TeacherAnalyticsScreen(user: user),
                        ),
                      );
                    },
                  ),
                  _DashboardCard(
                    icon: Icons.group_rounded,
                    title: 'Suivi des élèves',
                    subtitle: 'Progression des étudiants inscrits',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              StudentProgressScreen(user: user),
                        ),
                      );
                    },
                  ),
                          _DashboardCard(
                            icon: Icons.auto_awesome_rounded,
                            title: 'Générer quiz par IA',
                            subtitle: 'Créer un quiz automatiquement avec l\'IA',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const GenerateQuizAIScreen(),
                                ),
                              ).then((success) {
                                // Rafraîchir si un quiz a été généré
                                if (success == true) {
                                  // Les données seront rechargées automatiquement
                                }
                              });
                            },
                          ),
                          _DashboardCard(
                            icon: Icons.quiz_rounded,
                            title: 'Ajouter quiz',
                            subtitle: 'Créer un nouveau quiz manuellement',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const CreateStandaloneQuizScreen(),
                                ),
                              );
                            },
                          ),
                  _DashboardCard(
                    icon: Icons.assessment_rounded,
                    title: 'Scores des quizzes',
                    subtitle: 'Consulter les scores de tous les étudiants',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => QuizScoresScreen(user: user),
                        ),
                      );
                    },
                  ),
                  _DashboardCard(
                    icon: Icons.quiz_rounded,
                    title: 'Mes Quizzes',
                    subtitle: 'Consulter, modifier et gérer tous vos quizzes',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => TeacherQuizzesScreen(user: user),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Carte utilisée dans le dashboard
class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DashboardCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final cardColor = theme.cardColor;
    final shadowColor = theme.shadowColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: shadowColor.withValues(alpha: isDark ? 0.3 : 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        primaryColor.withValues(alpha: 0.15),
                        primaryColor.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    size: 28,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: primaryColor,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.secondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 18,
                  color: theme.colorScheme.secondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
