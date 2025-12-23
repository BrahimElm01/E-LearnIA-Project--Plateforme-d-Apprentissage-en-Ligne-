import 'package:flutter/material.dart';
import '../services/quiz_service.dart';
import '../models/quiz.dart';

class GenerateQuizAIScreen extends StatefulWidget {
  const GenerateQuizAIScreen({super.key});

  @override
  State<GenerateQuizAIScreen> createState() => _GenerateQuizAIScreenState();
}

class _GenerateQuizAIScreenState extends State<GenerateQuizAIScreen> {
  final QuizService _quizService = QuizService();
  final _topicController = TextEditingController();
  String _selectedDifficulty = 'BEGINNER';
  Quiz? _generatedQuiz;
  bool _isGenerating = false;
  String? _error;

  final List<Map<String, String>> _difficulties = const [
    {'value': 'BEGINNER', 'label': 'Débutant'},
    {'value': 'INTERMEDIATE', 'label': 'Intermédiaire'},
    {'value': 'ADVANCED', 'label': 'Avancé'},
  ];

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  Future<void> _generateQuiz() async {
    if (_topicController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un sujet pour le quiz.')),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
      _error = null;
      _generatedQuiz = null;
    });

    try {
      final quiz = await _quizService.generateQuizWithAI(
        topic: _topicController.text.trim(),
        difficulty: _selectedDifficulty,
      );
      
      if (!mounted) return;
      setState(() {
        _generatedQuiz = quiz;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Quiz généré avec succès ! 🎉'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la génération: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final onPrimaryColor = theme.colorScheme.onPrimary;
    final backgroundColor = theme.scaffoldBackgroundColor;
    final cardColor = theme.cardColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Générer un Quiz par IA'),
        backgroundColor: primaryColor,
        foregroundColor: onPrimaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section d'information
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, color: primaryColor, size: 28),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Génération automatique',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'L\'IA génère un quiz complet avec des questions et réponses',
                          style: theme.textTheme.bodyMedium?.copyWith(
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

            // Champ "Sujet du quiz"
            TextFormField(
              controller: _topicController,
              decoration: InputDecoration(
                labelText: 'Sujet du quiz *',
                hintText: 'Ex: Spring Boot, Flutter, Angular...',
                prefixIcon: const Icon(Icons.quiz_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Sélection de la difficulté
            InputDecorator(
              decoration: InputDecoration(
                labelText: 'Niveau de difficulté',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedDifficulty,
                  isExpanded: true,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedDifficulty = newValue!;
                    });
                  },
                  items: _difficulties.map<DropdownMenuItem<String>>((Map<String, String> difficulty) {
                    return DropdownMenuItem<String>(
                      value: difficulty['value'],
                      child: Text(difficulty['label']!),
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
                onPressed: _isGenerating ? null : _generateQuiz,
                icon: _isGenerating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome_rounded),
                label: Text(_isGenerating ? 'Génération en cours...' : 'Générer le quiz'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: onPrimaryColor,
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
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Erreur: $_error',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Aperçu du quiz généré
            if (_generatedQuiz != null) ...[
              const SizedBox(height: 32),
              Text(
                'Quiz généré avec succès !',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              Card(
                color: cardColor,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _generatedQuiz!.title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _generatedQuiz!.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(Icons.help_outline, size: 16, color: theme.colorScheme.secondary),
                          const SizedBox(width: 4),
                          Text(
                            '${_generatedQuiz!.questions.length} questions',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.trending_up, size: 16, color: theme.colorScheme.secondary),
                          const SizedBox(width: 4),
                          Text(
                            'Niveau: ${_getDifficultyLabel(_generatedQuiz!.level ?? "BEGINNER")}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop(true); // Retourner avec succès
                  },
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Terminé'),
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
          ],
        ),
      ),
    );
  }

  String _getDifficultyLabel(String level) {
    switch (level.toUpperCase()) {
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
}

