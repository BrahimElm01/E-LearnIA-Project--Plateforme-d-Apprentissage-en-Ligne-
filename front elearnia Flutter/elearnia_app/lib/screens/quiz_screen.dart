import 'package:flutter/material.dart';
import '../services/quiz_service.dart';
import '../models/student_course.dart';
import '../models/quiz.dart';

class QuizScreen extends StatefulWidget {
  final int? courseId; // Optionnel pour quiz standalone
  final int? quizId; // Pour quiz standalone
  final StudentCourse? course; // Optionnel pour quiz standalone

  const QuizScreen({
    super.key,
    this.courseId,
    this.quizId,
    this.course,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final QuizService _quizService = QuizService();
  Quiz? _quiz;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;
  final Map<int, String> _selectedAnswers = {}; // questionId -> answer

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  Future<void> _loadQuiz() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      Quiz quiz;
      if (widget.quizId != null) {
        // Quiz standalone
        quiz = await _quizService.getQuizById(widget.quizId!);
      } else if (widget.courseId != null) {
        // Quiz lié à un cours
        quiz = await _quizService.getQuizByCourse(widget.courseId!);
      } else {
        throw Exception('Quiz ID ou Course ID requis');
      }
      
      if (!mounted) return;
      setState(() {
        _quiz = quiz;
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

  Future<void> _submitQuiz() async {
    // Vérifier que toutes les questions ont une réponse
    if (_quiz == null) return;

    // Vérifier le nombre de tentatives restantes
    if (_quiz!.remainingAttempts <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous avez atteint le nombre maximum de tentatives. Vous ne pouvez plus soumettre ce quiz.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    for (final question in _quiz!.questions) {
      if (!_selectedAnswers.containsKey(question.id)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez répondre à toutes les questions'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      QuizResult result;
      if (widget.quizId != null) {
        // Quiz standalone
        result = await _quizService.submitStandaloneQuiz(widget.quizId!, _selectedAnswers);
      } else if (widget.courseId != null) {
        // Quiz lié à un cours
        result = await _quizService.submitQuiz(widget.courseId!, _selectedAnswers);
      } else {
        throw Exception('Quiz ID ou Course ID requis');
      }
      
      if (!mounted) return;

      setState(() => _isSubmitting = false);

      // Recharger le quiz pour mettre à jour les tentatives restantes
      await _loadQuiz();

      // Afficher le résultat
      _showQuizResult(result);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      
      // Vérifier si l'erreur est liée au nombre de tentatives
      final errorMessage = e.toString();
      if (errorMessage.contains('maximum de tentatives') || errorMessage.contains('maxAttempts')) {
        // Recharger le quiz pour mettre à jour les tentatives restantes
        await _loadQuiz();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vous avez atteint le nombre maximum de tentatives. Vous ne pouvez plus soumettre ce quiz.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showQuizResult(QuizResult result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              result.passed ? Icons.check_circle : Icons.cancel,
              color: result.passed ? Colors.green : Colors.red,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                result.passed ? 'Quiz réussi ! 🎉' : 'Quiz échoué',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: result.passed ? Colors.green : Colors.red,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Score obtenu : ${result.score.toStringAsFixed(1)}%',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tentative : ${result.attemptNumber}/${_quiz!.maxAttempts}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            if (result.remainingAttempts > 0)
              Text(
                'Tentatives restantes : ${result.remainingAttempts}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            const SizedBox(height: 16),
            if (result.passed)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Félicitations ! Le cours est maintenant marqué comme terminé.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        result.remainingAttempts > 0
                            ? 'Score minimum requis : ${_quiz!.passingScore}%. Vous pouvez réessayer.'
                            : 'Vous avez atteint le nombre maximum de tentatives.',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          if (!result.passed && result.remainingAttempts > 0)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Réinitialiser les réponses pour une nouvelle tentative
                setState(() {
                  _selectedAnswers.clear();
                });
              },
              child: const Text('Réessayer'),
            ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (result.passed || result.courseCompleted) {
                Navigator.of(context).pop(true); // Retourner true si le cours est complété
              } else {
                Navigator.of(context).pop(false);
              }
            },
            child: Text(result.passed ? 'Continuer' : 'Fermer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Quiz'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Quiz'),
        ),
        body: Center(
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
                onPressed: _loadQuiz,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (_quiz == null || _quiz!.questions.isEmpty) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Quiz'),
        ),
        body: Center(
          child: Text(
            'Aucun quiz disponible',
            style: TextStyle(color: theme.colorScheme.secondary),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Quiz'),
        actions: [
          if (_quiz != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'Score min: ${_quiz!.passingScore}%',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête du quiz
                  Container(
                    padding: const EdgeInsets.all(20),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _quiz!.title,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        if (_quiz!.description.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            _quiz!.description,
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.help_outline, size: 16, color: theme.colorScheme.secondary),
                            const SizedBox(width: 4),
                            Text(
                              '${_quiz!.questions.length} questions',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.secondary,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(
                              Icons.repeat,
                              size: 16,
                              color: _quiz!.remainingAttempts > 0 ? Colors.grey[600] : Colors.red,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _quiz!.remainingAttempts > 0
                                  ? '${_quiz!.remainingAttempts} tentative${_quiz!.remainingAttempts > 1 ? 's' : ''} restante${_quiz!.remainingAttempts > 1 ? 's' : ''}'
                                  : 'Aucune tentative restante',
                              style: TextStyle(
                                fontSize: 12,
                                color: _quiz!.remainingAttempts > 0 ? Colors.grey[600] : Colors.red,
                                fontWeight: _quiz!.remainingAttempts > 0 ? FontWeight.normal : FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        if (_quiz!.remainingAttempts <= 0) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red, width: 1),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.warning, color: Colors.red, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Vous avez atteint le nombre maximum de tentatives. Vous ne pouvez plus soumettre ce quiz.',
                                    style: const TextStyle(
                                      fontSize: 12,
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
                  const SizedBox(height: 24),

                  // Questions
                  ..._quiz!.questions.asMap().entries.map((entry) {
                    final index = entry.key;
                    final question = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: _QuestionCard(
                        questionNumber: index + 1,
                        question: question,
                        selectedAnswer: _selectedAnswers[question.id],
                        onAnswerSelected: (answer) {
                          setState(() {
                            _selectedAnswers[question.id] = answer;
                          });
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // Bouton de soumission
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: theme.brightness == Brightness.dark ? 0.3 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: (_isSubmitting || (_quiz != null && _quiz!.remainingAttempts <= 0)) ? null : _submitQuiz,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (_quiz != null && _quiz!.remainingAttempts <= 0) ? Colors.grey : theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          (_quiz != null && _quiz!.remainingAttempts <= 0)
                              ? 'Tentatives épuisées'
                              : 'Soumettre le quiz',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final int questionNumber;
  final Question question;
  final String? selectedAnswer;
  final Function(String) onAnswerSelected;

  const _QuestionCard({
    required this.questionNumber,
    required this.question,
    required this.selectedAnswer,
    required this.onAnswerSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
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
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Question $questionNumber',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${question.points} point${question.points > 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            question.text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          ...question.options.map((option) {
            final isSelected = selectedAnswer == option;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () => onAnswerSelected(option),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary.withValues(alpha: 0.1)
                        : isDark ? Colors.grey[800] : Colors.grey[50],
                    border: Border.all(
                      color: isSelected ? theme.colorScheme.primary : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? theme.colorScheme.primary : (isDark ? Colors.grey[600]! : Colors.grey[400]!),
                            width: 2,
                          ),
                          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                        ),
                        child: isSelected
                            ? Icon(
                                Icons.check,
                                size: 16,
                                color: theme.colorScheme.onPrimary,
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          option,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

