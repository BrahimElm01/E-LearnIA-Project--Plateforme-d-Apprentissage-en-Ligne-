import 'package:flutter/material.dart';
import '../models/generated_course.dart';
import '../services/course_service.dart';
import 'teacher_courses_screen.dart';
import '../models/user.dart';
import '../widgets/safe_network_image.dart';

class AICourseGeneratorScreen extends StatefulWidget {
  final User user;

  const AICourseGeneratorScreen({
    super.key,
    required this.user,
  });

  @override
  State<AICourseGeneratorScreen> createState() => _AICourseGeneratorScreenState();
}

class _AICourseGeneratorScreenState extends State<AICourseGeneratorScreen> {
  final CourseService _courseService = CourseService();
  final TextEditingController _ideaController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  String _selectedLevel = 'intermédiaire';
  GeneratedCourse? _generatedCourse;
  bool _isGenerating = false;
  bool _isCreating = false;
  String? _error;

  final List<Map<String, String>> _levels = const [
    {'value': 'débutant', 'label': 'Débutant'},
    {'value': 'intermédiaire', 'label': 'Intermédiaire'},
    {'value': 'avancé', 'label': 'Avancé'},
  ];

  @override
  void dispose() {
    _ideaController.dispose();
    super.dispose();
  }

  Future<void> _generateCourse() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isGenerating = true;
      _error = null;
      _generatedCourse = null;
    });

    try {
      final generated = await _courseService.generateCourseWithAI(
        idea: _ideaController.text.trim(),
        level: _selectedLevel,
      );

      if (!mounted) return;
      setState(() {
        _generatedCourse = generated;
        _isGenerating = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isGenerating = false;
      });
    }
  }

  Future<void> _createCourse() async {
    if (_generatedCourse == null) return;

    setState(() {
      _isCreating = true;
      _error = null;
    });

    try {
      await _courseService.generateAndCreateCourse(
        idea: _ideaController.text.trim(),
        level: _selectedLevel,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cours créé avec succès !'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => TeacherCoursesScreen(user: widget.user),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isCreating = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final backgroundColor = theme.scaffoldBackgroundColor;
    final cardColor = theme.cardColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Enseigner avec IA'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryColor.withValues(alpha: 0.1),
                      primaryColor.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, size: 40, color: primaryColor),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Génération automatique',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'L\'IA génère le plan, le quiz et les objectifs',
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Champ idée
              TextFormField(
                controller: _ideaController,
                decoration: InputDecoration(
                  labelText: 'Idée du cours *',
                  hintText: 'Ex: Introduction à Spring Boot, Flutter pour débutants...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.lightbulb_outline),
                ),
                maxLines: 3,
                validator: (value) =>
                    value!.isEmpty ? 'Veuillez entrer une idée de cours' : null,
              ),
              const SizedBox(height: 16),

              // Sélection niveau
              InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Niveau du cours',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedLevel,
                    isExpanded: true,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedLevel = newValue!;
                      });
                    },
                    items: _levels.map<DropdownMenuItem<String>>((Map<String, String> level) {
                      return DropdownMenuItem<String>(
                        value: level['value'],
                        child: Text(level['label']!),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Bouton générer
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isGenerating ? null : _generateCourse,
                  icon: _isGenerating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome_rounded),
                  label: Text(_isGenerating ? 'Génération en cours...' : 'Générer le cours'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              // Erreur
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Résultat généré
              if (_generatedCourse != null) ...[
                const SizedBox(height: 32),
                _buildGeneratedCoursePreview(_generatedCourse!, theme, primaryColor, cardColor),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGeneratedCoursePreview(
    GeneratedCourse course,
    ThemeData theme,
    Color primaryColor,
    Color cardColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cours généré',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 16),

        // Miniature
        if (course.imageUrl != null && course.imageUrl!.isNotEmpty)
          Card(
            color: cardColor,
            clipBehavior: Clip.antiAlias,
            child: SafeNetworkImage(
              imageUrl: SafeNetworkImage.normalizeImageUrl(course.imageUrl),
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
            ),
          ),
        const SizedBox(height: 16),
        
        // Titre et description
        Card(
          color: cardColor,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  course.description,
                  style: TextStyle(
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Résumé
        if (course.summary.isNotEmpty) ...[
          _buildSection(
            'Résumé',
            course.summary,
            Icons.summarize_rounded,
            theme,
            primaryColor,
            cardColor,
          ),
          const SizedBox(height: 16),
        ],

        // Objectifs
        if (course.objectives.isNotEmpty) ...[
          _buildSection(
            'Objectifs d\'apprentissage',
            course.objectives.map((obj) => '• $obj').join('\n'),
            Icons.flag_rounded,
            theme,
            primaryColor,
            cardColor,
          ),
          const SizedBox(height: 16),
        ],

        // Plan du cours
        if (course.lessons.isNotEmpty) ...[
          Text(
            'Plan du cours (${course.lessons.length} leçons)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          ...course.lessons.map((lesson) => _buildLessonCard(lesson, theme, primaryColor, cardColor)),
          const SizedBox(height: 16),
        ],

        // Quiz
        if (course.quiz != null) ...[
          _buildQuizPreview(course.quiz!, theme, primaryColor, cardColor),
          const SizedBox(height: 24),
        ],

        // Bouton créer
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _isCreating ? null : _createCourse,
            icon: _isCreating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_circle_outline),
            label: Text(_isCreating ? 'Création en cours...' : 'Créer ce cours'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection(
    String title,
    String content,
    IconData icon,
    ThemeData theme,
    Color primaryColor,
    Color cardColor,
  ) {
    return Card(
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: TextStyle(
                color: theme.colorScheme.secondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonCard(
    GeneratedLesson lesson,
    ThemeData theme,
    Color primaryColor,
    Color cardColor,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: cardColor,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: primaryColor.withValues(alpha: 0.1),
          child: Text(
            '${lesson.orderIndex}',
            style: TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          lesson.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: primaryColor,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(lesson.description),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: theme.colorScheme.secondary),
                const SizedBox(width: 4),
                Text(
                  '${lesson.estimatedDuration} min',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.secondary,
                  ),
                ),
                if (lesson.videoUrl != null && lesson.videoUrl!.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  Icon(Icons.play_circle_outline, size: 14, color: Colors.red),
                  const SizedBox(width: 4),
                  Text(
                    'Vidéo YouTube',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizPreview(
    GeneratedQuiz quiz,
    ThemeData theme,
    Color primaryColor,
    Color cardColor,
  ) {
    return Card(
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.quiz_rounded, color: primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Quiz généré',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              quiz.title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              quiz.description,
              style: TextStyle(
                color: theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${quiz.questions.length} questions générées',
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.secondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

