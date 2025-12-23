import 'dart:math';
import 'package:flutter/material.dart';

import '../models/user.dart';
import '../models/student_course.dart';
import '../services/auth_service.dart';
import '../services/course_service.dart';
import '../services/quiz_service.dart';
import '../models/quiz.dart';
import '../widgets/safe_network_image.dart';
import 'login_screen.dart';
import 'student_courses_screen.dart';
import 'profile_screen.dart';
import 'course_detail_screen.dart';
import 'category_courses_screen.dart';
import 'quiz_screen.dart';
import 'chatbot_screen.dart';

class HomeScreen extends StatefulWidget {
  final User user;

  const HomeScreen({
    super.key,
    required this.user,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final AuthService _authService = AuthService();

  void _changeTab(int index) {
    setState(() {
      _currentIndex = index;
    });
    // Si on revient sur l'écran d'accueil, recharger les données
    if (index == 0) {
      // Les données seront rechargées via le RefreshIndicator ou manuellement
    }
  }

  Future<void> _logout() async {
    try {
      await _authService.logout();
    } finally {
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final pages = <Widget>[
      _HomeTab(user: widget.user, changeTab: _changeTab, key: ValueKey('home')),
      StudentCoursesScreen(user: widget.user, key: ValueKey('courses')),
      const _QuizzesTab(),
      ProfileScreen(
        user: widget.user,
        isTeacher: false,
        onLogout: _logout,
      ),
    ];

    final titles = ['Accueil', 'Mes cours', 'Quizzes', 'Profil'];
    final icons = [
      Icons.home_rounded,
      Icons.menu_book_rounded,
      Icons.quiz_rounded,
      Icons.person_rounded,
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: pages,
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _changeTab,
        type: BottomNavigationBarType.fixed,
          selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor: theme.colorScheme.secondary,
        showUnselectedLabels: true,
          elevation: 0,
          backgroundColor: theme.cardColor,
          selectedFontSize: 12,
          unselectedFontSize: 12,
        items: List.generate(titles.length, (index) {
          return BottomNavigationBarItem(
            icon: Icon(icons[index]),
            label: titles[index],
          );
        }),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const ChatBotScreen(),
            ),
          );
        },
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.chat_bubble_rounded),
        tooltip: 'Assistant virtuel',
      ),
    );
  }
}

// ================== ONGLET ACCUEIL AMÉLIORÉ ==================

class _HomeTab extends StatefulWidget {
  final User user;
  final void Function(int index) changeTab;

  const _HomeTab({
    super.key,
    required this.user,
    required this.changeTab,
  });

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  final CourseService _courseService = CourseService();
  final TextEditingController _searchController = TextEditingController();
  List<StudentCourse> _allCourses = [];
  List<StudentCourse> _filteredCourses = [];
  bool _isLoading = true;
  String? _error;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadCourses();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      _isSearching = query.isNotEmpty;
      if (_isSearching) {
        _filteredCourses = _allCourses.where((course) {
          final title = course.title.toLowerCase();
          final description = course.description.toLowerCase();
          return title.contains(query) || description.contains(query);
        }).toList();
      } else {
        _filteredCourses = [];
      }
    });
  }

  Future<void> _loadCourses() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final courses = await _courseService.getStudentCourses();
      if (!mounted) return;
      setState(() {
        _allCourses = courses;
        _isLoading = false;
        // Réappliquer le filtre de recherche si actif
        if (_isSearching && _searchController.text.isNotEmpty) {
          _onSearchChanged();
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _getCourseCategory(StudentCourse course) {
    final titleLower = course.title.toLowerCase();
    final descLower = course.description.toLowerCase();
    final text = '$titleLower $descLower';

    // Programming
    if (text.contains('flutter') || text.contains('dart') || text.contains('programming') || 
        text.contains('code') || text.contains('java') || text.contains('spring') ||
        text.contains('html') || text.contains('css') || text.contains('javascript') ||
        text.contains('python') || text.contains('react') || text.contains('node') ||
        text.contains('angular') || text.contains('vue') || text.contains('php') ||
        text.contains('c++') || text.contains('c#') || text.contains('swift') ||
        text.contains('kotlin') || text.contains('ruby') || text.contains('go') ||
        text.contains('rust') || text.contains('algorithm') || text.contains('database') ||
        text.contains('sql') || text.contains('api') || text.contains('backend') ||
        text.contains('frontend') || text.contains('web development') || text.contains('mobile')) {
      return 'Programming';
    }
    // Design
    else if (text.contains('design') || text.contains('ui') || text.contains('ux') ||
               text.contains('graphic') || text.contains('visual') || text.contains('photoshop') ||
               text.contains('illustrator') || text.contains('figma') || text.contains('sketch') ||
               text.contains('adobe') || text.contains('typography') || text.contains('logo') ||
               text.contains('branding') || text.contains('animation') || text.contains('3d')) {
      return 'Design';
    }
    // Business
    else if (text.contains('business') || text.contains('marketing') || 
               text.contains('management') || text.contains('finance') || text.contains('accounting') ||
               text.contains('entrepreneurship') || text.contains('sales') || text.contains('strategy') ||
               text.contains('leadership') || text.contains('project management') || text.contains('hr') ||
               text.contains('human resources') || text.contains('economics') || text.contains('investment')) {
      return 'Business';
    }
    // Science
    else if (text.contains('science') || text.contains('math') || text.contains('physics') ||
               text.contains('chemistry') || text.contains('biology') || text.contains('engineering') ||
               text.contains('data science') || text.contains('machine learning') || text.contains('ai') ||
               text.contains('artificial intelligence') || text.contains('statistics') || text.contains('research')) {
      return 'Science';
    }
    // Languages
    else if (text.contains('language') || text.contains('english') || text.contains('french') ||
               text.contains('spanish') || text.contains('german') || text.contains('italian') ||
               text.contains('chinese') || text.contains('japanese') || text.contains('arabic') ||
               text.contains('translation') || text.contains('grammar') || text.contains('vocabulary') ||
               text.contains('communication') || text.contains('linguistics')) {
      return 'Languages';
    }
    // Health & Fitness
    else if (text.contains('health') || text.contains('fitness') || text.contains('nutrition') ||
               text.contains('yoga') || text.contains('meditation') || text.contains('wellness') ||
               text.contains('diet') || text.contains('exercise') || text.contains('workout') ||
               text.contains('mental health') || text.contains('therapy')) {
      return 'Health';
    }
    // Music & Arts
    else if (text.contains('music') || text.contains('art') || text.contains('drawing') ||
               text.contains('painting') || text.contains('photography') || text.contains('video') ||
               text.contains('film') || text.contains('cinema') || text.contains('dance') ||
               text.contains('theater') || text.contains('acting') || text.contains('singing')) {
      return 'Arts';
    }
    return 'Other';
  }

  List<StudentCourse> _getCoursesByCategory(String category) {
    return _allCourses.where((course) => _getCourseCategory(course) == category).toList();
  }

  Map<String, int> _getCategoryCounts() {
    final counts = <String, int>{};
    for (final course in _allCourses) {
      final category = _getCourseCategory(course);
      counts[category] = (counts[category] ?? 0) + 1;
    }
    return counts;
  }

  List<StudentCourse> _getInProgressCourses() {
    return _allCourses.where((course) => course.progress > 0 && course.progress < 100).toList()
      ..sort((a, b) => b.progress.compareTo(a.progress));
  }

  List<StudentCourse> _getRecommendedCourses() {
    final notInProgress = _allCourses.where((course) => course.progress == 0).toList();
    notInProgress.shuffle(Random());
    return notInProgress.take(5).toList();
  }

  int _getTotalProgress() {
    if (_allCourses.isEmpty) return 0;
    final total = _allCourses.fold<double>(0, (sum, course) => sum + course.progress);
    return (total / _allCourses.length).round();
  }

  int _getCompletedCourses() {
    return _allCourses.where((course) => course.progress >= 100).length;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final background = theme.scaffoldBackgroundColor;

    final firstName = widget.user.fullName.isNotEmpty
        ? widget.user.fullName.split(' ').first
        : 'Étudiant';

    if (_isLoading) {
    return Scaffold(
      backgroundColor: background,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(primary),
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: theme.colorScheme.secondary),
              const SizedBox(height: 16),
              Text('Erreur: $_error', style: TextStyle(color: theme.colorScheme.secondary)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadCourses,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    final categoryCounts = _getCategoryCounts();
    final inProgressCourses = _getInProgressCourses();
    final recommendedCourses = _getRecommendedCourses();
    final totalProgress = _getTotalProgress();
    final completedCourses = _getCompletedCourses();
    
    // Utiliser les cours filtrés si on est en mode recherche
    final coursesToDisplay = _isSearching ? _filteredCourses : _allCourses;

    return Scaffold(
      backgroundColor: background,
      body: RefreshIndicator(
        onRefresh: _loadCourses,
        color: primary,
        child: CustomScrollView(
          slivers: [
            // App Bar avec gradient
            SliverAppBar(
              expandedHeight: 180,
              floating: false,
              pinned: true,
              elevation: 0,
              backgroundColor: primary,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        primary,
                        primary.withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                                  Text(
                                    'Bonjour,',
                        style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        firstName,
                        style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(12),
                    child: Text(
                      firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U',
                      style: const TextStyle(
                                    fontSize: 24,
                        fontWeight: FontWeight.bold,
                                    color: Colors.white,
                      ),
                    ),
                  ),
                ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Contenu principal
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Statistiques
                    _StatsCard(
                      totalProgress: totalProgress,
                      completedCourses: completedCourses,
                      totalCourses: _allCourses.length,
                    ),
              const SizedBox(height: 24),

                    // Barre de recherche
              Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                            color: Colors.black.withValues(alpha: theme.brightness == Brightness.dark ? 0.3 : 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher des cours...',
                    hintStyle: TextStyle(
                      color: theme.colorScheme.secondary,
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(Icons.search, color: theme.colorScheme.secondary),
                    suffixIcon: _isSearching
                        ? IconButton(
                            icon: Icon(Icons.clear, color: theme.colorScheme.secondary),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 24),

                    // Résultats de recherche ou contenu normal
                    if (_isSearching) ...[
                      // Section résultats de recherche
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Résultats de recherche',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          Text(
                            '${_filteredCourses.length} résultat${_filteredCourses.length > 1 ? 's' : ''}',
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_filteredCourses.isEmpty)
                        _EmptyStateCard(
                          icon: Icons.search_off,
                          message: 'Aucun cours trouvé',
                          subtitle: 'Essayez avec d\'autres mots-clés',
                        )
                      else
                        ..._filteredCourses.map((course) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _InProgressCourseCard(
                                course: course,
                                onTap: () async {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => CourseDetailScreen(course: course),
                                    ),
                                  );
                                  _loadCourses();
                                },
                              ),
                            )),
                    ] else ...[
                    // Catégories
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
              Text(
                          'Catégories',
                style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                ),
                        ),
                      ],
              ),
              const SizedBox(height: 12),
                    SizedBox(
                      height: 120,
                      child: ListView(
                scrollDirection: Axis.horizontal,
                        children: [
                          if (categoryCounts['Programming'] != null && categoryCounts['Programming']! > 0)
                    _CategoryCard(
                      title: 'Programming',
                              count: categoryCounts['Programming']!,
                              icon: Icons.code_rounded,
                              color: const Color(0xFF6366F1),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => CategoryCoursesScreen(
                                      categoryName: 'Programming',
                                      courses: _getCoursesByCategory('Programming'),
                                      categoryColor: const Color(0xFF6366F1),
                                      categoryIcon: Icons.code_rounded,
                                    ),
                                  ),
                                );
                              },
                            ),
                          if (categoryCounts['Design'] != null && categoryCounts['Design']! > 0) ...[
                            const SizedBox(width: 12),
                    _CategoryCard(
                      title: 'Design',
                              count: categoryCounts['Design']!,
                              icon: Icons.brush_rounded,
                              color: const Color(0xFFEC4899),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => CategoryCoursesScreen(
                                      categoryName: 'Design',
                                      courses: _getCoursesByCategory('Design'),
                                      categoryColor: const Color(0xFFEC4899),
                                      categoryIcon: Icons.brush_rounded,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                          if (categoryCounts['Business'] != null && categoryCounts['Business']! > 0) ...[
                            const SizedBox(width: 12),
                    _CategoryCard(
                      title: 'Business',
                              count: categoryCounts['Business']!,
                              icon: Icons.business_center_rounded,
                              color: const Color(0xFF10B981),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => CategoryCoursesScreen(
                                      categoryName: 'Business',
                                      courses: _getCoursesByCategory('Business'),
                                      categoryColor: const Color(0xFF10B981),
                                      categoryIcon: Icons.business_center_rounded,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                          if (categoryCounts['Science'] != null && categoryCounts['Science']! > 0) ...[
                            const SizedBox(width: 12),
                            _CategoryCard(
                              title: 'Science',
                              count: categoryCounts['Science']!,
                              icon: Icons.science_rounded,
                              color: const Color(0xFF3B82F6),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => CategoryCoursesScreen(
                                      categoryName: 'Science',
                                      courses: _getCoursesByCategory('Science'),
                                      categoryColor: const Color(0xFF3B82F6),
                                      categoryIcon: Icons.science_rounded,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                          if (categoryCounts['Languages'] != null && categoryCounts['Languages']! > 0) ...[
                            const SizedBox(width: 12),
                            _CategoryCard(
                              title: 'Languages',
                              count: categoryCounts['Languages']!,
                              icon: Icons.language_rounded,
                              color: const Color(0xFF8B5CF6),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => CategoryCoursesScreen(
                                      categoryName: 'Languages',
                                      courses: _getCoursesByCategory('Languages'),
                                      categoryColor: const Color(0xFF8B5CF6),
                                      categoryIcon: Icons.language_rounded,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                          if (categoryCounts['Health'] != null && categoryCounts['Health']! > 0) ...[
                            const SizedBox(width: 12),
                            _CategoryCard(
                              title: 'Health',
                              count: categoryCounts['Health']!,
                              icon: Icons.favorite_rounded,
                              color: const Color(0xFFEF4444),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => CategoryCoursesScreen(
                                      categoryName: 'Health & Fitness',
                                      courses: _getCoursesByCategory('Health'),
                                      categoryColor: const Color(0xFFEF4444),
                                      categoryIcon: Icons.favorite_rounded,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                          if (categoryCounts['Arts'] != null && categoryCounts['Arts']! > 0) ...[
                            const SizedBox(width: 12),
                            _CategoryCard(
                              title: 'Arts',
                              count: categoryCounts['Arts']!,
                              icon: Icons.palette_rounded,
                              color: const Color(0xFFF59E0B),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => CategoryCoursesScreen(
                                      categoryName: 'Music & Arts',
                                      courses: _getCoursesByCategory('Arts'),
                                      categoryColor: const Color(0xFFF59E0B),
                                      categoryIcon: Icons.palette_rounded,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                          if (categoryCounts['Other'] != null && categoryCounts['Other']! > 0) ...[
                            const SizedBox(width: 12),
                            _CategoryCard(
                              title: 'Autres',
                              count: categoryCounts['Other']!,
                              icon: Icons.category_rounded,
                              color: const Color(0xFF6B7280),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => CategoryCoursesScreen(
                                      categoryName: 'Autres',
                                      courses: _getCoursesByCategory('Other'),
                                      categoryColor: const Color(0xFF6B7280),
                                      categoryIcon: Icons.category_rounded,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
              const SizedBox(height: 24),

                    // En cours
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'En cours',
                    style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                    ),
                        ),
                        if (inProgressCourses.isNotEmpty)
                          TextButton(
                            onPressed: () => widget.changeTab(1),
                            child: const Text('Voir tout'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
                    if (inProgressCourses.isEmpty)
                      _EmptyStateCard(
                        icon: Icons.play_circle_outline,
                        message: 'Aucun cours en cours',
                        subtitle: 'Commencez un nouveau cours pour voir votre progression ici',
                      )
                    else
                      ...inProgressCourses.take(3).map((course) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _InProgressCourseCard(
                              course: course,
                              onTap: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => CourseDetailScreen(course: course),
                                  ),
                                );
                                // Recharger les cours quand on revient (pour mettre à jour les reviews)
                                _loadCourses();
                              },
                            ),
                          )),
              const SizedBox(height: 24),

                    // Recommandés
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                          'Recommandés',
                    style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                    ),
                  ),
                  TextButton(
                          onPressed: () => widget.changeTab(1),
                          child: const Text('Voir tout'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
                    if (recommendedCourses.isEmpty)
                      _EmptyStateCard(
                        icon: Icons.school_outlined,
                        message: 'Aucun cours recommandé',
                        subtitle: 'Explorez les cours disponibles dans "Mes cours"',
                      )
                    else
              SizedBox(
                        height: 200,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                          children: recommendedCourses.map((course) {
                            return Padding(
                              padding: EdgeInsets.only(
                                right: recommendedCourses.last == course ? 0 : 12,
                              ),
                              child: _RecommendedCourseCard(
                                course: course,
                                onTap: () async {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => CourseDetailScreen(course: course),
                                    ),
                                  );
                                  // Recharger les cours quand on revient (pour mettre à jour les reviews)
                                  _loadCourses();
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    const SizedBox(height: 24),
                    ],
                  ],
                ),
                ),
              ),
            ],
          ),
        ),
    );
  }
}

// ====== Carte de statistiques ======
class _StatsCard extends StatelessWidget {
  final int totalProgress;
  final int completedCourses;
  final int totalCourses;

  const _StatsCard({
    required this.totalProgress,
    required this.completedCourses,
    required this.totalCourses,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.black,
            Colors.black.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Progression globale',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$totalProgress%',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$completedCourses sur $totalCourses cours terminés',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: CircularProgressIndicator(
                value: totalProgress / 100,
                strokeWidth: 6,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                backgroundColor: Colors.white.withOpacity(0.3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ====== Carte catégorie améliorée ======
class _CategoryCard extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 140,
        height: 120,
        padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.min,
        children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
          Text(
            title,
            style: TextStyle(
                      fontSize: 13,
              fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
            ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
          ),
                  const SizedBox(height: 2),
          Text(
                    '$count cours',
                    style: TextStyle(
              fontSize: 11,
                      color: theme.colorScheme.secondary,
            ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

// ====== Carte cours "En cours" améliorée ======
class _InProgressCourseCard extends StatelessWidget {
  final StudentCourse course;
  final VoidCallback onTap;

  const _InProgressCourseCard({
    required this.course,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress = course.progress / 100;
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
              width: 70,
              height: 70,
            decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SafeNetworkImage(
                  imageUrl: course.imageUrl,
                  fit: BoxFit.cover,
                  errorWidget: Icon(Icons.play_circle_outline, color: primary, size: 32),
                ),
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
                  style: TextStyle(
                      fontSize: 15,
                    fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                    minHeight: 6,
                    backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      course.progress >= 100 ? Colors.green : primary,
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                Text(
                        '${course.progress.toStringAsFixed(0)}% complété',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (course.progress >= 100)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Terminé',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
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

// ====== Carte cours "Recommandé" améliorée ======
class _RecommendedCourseCard extends StatelessWidget {
  final StudentCourse course;
  final VoidCallback onTap;

  const _RecommendedCourseCard({
    required this.course,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 240,
      decoration: BoxDecoration(
        color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              height: 110,
            decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: course.imageUrl != null && course.imageUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      child: SafeNetworkImage(
                        imageUrl: course.imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorWidget: Center(
                          child: Icon(Icons.play_circle_outline, size: 48, color: theme.colorScheme.secondary),
                        ),
                      ),
                    )
                  : Center(
                      child: Icon(Icons.play_circle_outline, size: 48, color: theme.colorScheme.secondary),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
          Text(
                    course.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                      fontSize: 14,
              fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.person_outline, size: 12, color: theme.colorScheme.secondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          course.teacherName.isNotEmpty ? course.teacherName : 'Professeur',
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ====== Carte état vide ======
class _EmptyStateCard extends StatelessWidget {
  final IconData icon;
  final String message;
  final String subtitle;

  const _EmptyStateCard({
    required this.icon,
    required this.message,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 64, color: theme.colorScheme.secondary),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ================== ONGLET QUIZZES ==================

class _QuizzesTab extends StatefulWidget {
  const _QuizzesTab({super.key});

  @override
  State<_QuizzesTab> createState() => _QuizzesTabState();
}

class _QuizzesTabState extends State<_QuizzesTab> {
  final QuizService _quizService = QuizService();
  List<QuizSummary> _quizzes = [];
  String _selectedLevel = 'ALL';
  bool _isLoading = true;
  String? _error;

  final List<Map<String, String>> _levels = [
    {'value': 'ALL', 'label': 'Tous les niveaux'},
    {'value': 'BEGINNER', 'label': 'Débutant'},
    {'value': 'INTERMEDIATE', 'label': 'Intermédiaire'},
    {'value': 'ADVANCED', 'label': 'Avancé'},
  ];

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
      final quizzes = await _quizService.getAvailableQuizzes(
        level: _selectedLevel == 'ALL' ? null : _selectedLevel,
      );
      if (!mounted) return;
      setState(() {
        _quizzes = quizzes;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = theme.scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            // Header avec titre et filtre
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quizzes',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Filtre de niveau
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _levels.map((level) {
                        final isSelected = _selectedLevel == level['value'];
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(level['label']!),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedLevel = level['value']!;
                                });
                                _loadQuizzes();
                              }
                            },
                            selectedColor: theme.colorScheme.primary,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : theme.colorScheme.primary,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
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
                              Icon(Icons.error_outline, size: 64, color: theme.colorScheme.secondary),
                              const SizedBox(height: 16),
                              Text(
                                'Erreur',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 32),
                                child: Text(
                                  _error!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: theme.colorScheme.secondary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: _loadQuizzes,
                                child: const Text('Réessayer'),
                              ),
                            ],
                          ),
                        )
                      : _quizzes.isEmpty
                          ? Center(
                              child: Text(
                                'Aucun quiz disponible',
                                style: TextStyle(
                                  color: theme.colorScheme.secondary,
                                  fontSize: 16,
                                ),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadQuizzes,
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                                itemCount: _quizzes.length,
                                itemBuilder: (context, index) {
                                  final quiz = _quizzes[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _QuizCard(
                                      quiz: quiz,
                                      onTap: () async {
                                        try {
                                          final fullQuiz = await _quizService.getQuizById(quiz.id);
                                          if (!mounted) return;
                                          final result = await Navigator.of(context).push<bool>(
                                            MaterialPageRoute(
                                              builder: (_) => QuizScreen(
                                                quizId: quiz.id,
                                                courseId: null,
                                                course: null,
                                              ),
                                            ),
                                          );
                                          if (result == true) {
                                            _loadQuizzes(); // Recharger pour mettre à jour les tentatives
                                          }
                                        } catch (e) {
                                          if (!mounted) return;
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Erreur: $e'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuizCard extends StatelessWidget {
  final QuizSummary quiz;
  final VoidCallback onTap;

  const _QuizCard({
    required this.quiz,
    required this.onTap,
  });

  String _getLevelLabel(String level) {
    switch (level) {
      case 'BEGINNER':
        return 'Débutant';
      case 'INTERMEDIATE':
        return 'Intermédiaire';
      case 'ADVANCED':
        return 'Avancé';
      default:
        return level;
    }
  }

  Color _getLevelColor(String level) {
    switch (level) {
      case 'BEGINNER':
        return Colors.green;
      case 'INTERMEDIATE':
        return Colors.orange;
      case 'ADVANCED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return InkWell(
      onTap: quiz.remainingAttempts > 0 ? onTap : null,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    quiz.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getLevelColor(quiz.level).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getLevelLabel(quiz.level),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _getLevelColor(quiz.level),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              quiz.description,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.help_outline, size: 16, color: theme.colorScheme.secondary),
                const SizedBox(width: 4),
                Text(
                  '${quiz.questionCount} Questions',
                  style: TextStyle(fontSize: 11, color: theme.colorScheme.secondary),
                ),
                const SizedBox(width: 16),
                Icon(Icons.repeat, size: 16, color: theme.colorScheme.secondary),
                const SizedBox(width: 4),
                Text(
                  quiz.remainingAttempts > 0
                      ? '${quiz.remainingAttempts} tentative${quiz.remainingAttempts > 1 ? 's' : ''} restante${quiz.remainingAttempts > 1 ? 's' : ''}'
                      : 'Aucune tentative restante',
                  style: TextStyle(
                    fontSize: 11,
                    color: quiz.remainingAttempts > 0
                        ? theme.colorScheme.secondary
                        : Colors.red,
                    fontWeight: quiz.remainingAttempts > 0
                        ? FontWeight.normal
                        : FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (quiz.remainingAttempts <= 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tentatives épuisées',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

