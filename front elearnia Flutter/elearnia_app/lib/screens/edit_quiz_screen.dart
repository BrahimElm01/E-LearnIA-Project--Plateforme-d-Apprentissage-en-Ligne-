import 'package:flutter/material.dart';
import '../models/quiz.dart';
import '../services/quiz_service.dart';

class EditQuizScreen extends StatefulWidget {
  final Quiz quiz;

  const EditQuizScreen({
    super.key,
    required this.quiz,
  });

  @override
  State<EditQuizScreen> createState() => _EditQuizScreenState();
}

class _EditQuizScreenState extends State<EditQuizScreen> {
  final QuizService _quizService = QuizService();
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _passingScoreController;
  late final TextEditingController _maxAttemptsController;

  List<_QuestionForm> _questions = [];
  late String _selectedLevel;
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _questionKeys = {};
  final Map<int, bool> _questionSaving = {}; // Pour suivre l'état de sauvegarde de chaque question

  final List<Map<String, String>> _levels = [
    {'value': 'BEGINNER', 'label': 'Débutant'},
    {'value': 'INTERMEDIATE', 'label': 'Intermédiaire'},
    {'value': 'ADVANCED', 'label': 'Avancé'},
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.quiz.title);
    _descriptionController = TextEditingController(text: widget.quiz.description);
    _passingScoreController = TextEditingController(text: widget.quiz.passingScore.toString());
    _maxAttemptsController = TextEditingController(text: widget.quiz.maxAttempts.toString());
    _selectedLevel = widget.quiz.level ?? 'BEGINNER';

    // Initialiser les clés pour les questions
    _questionKeys.clear();
    
    // Initialiser les questions
    _questions = widget.quiz.questions.asMap().entries.map((entry) {
      final index = entry.key;
      final q = entry.value;
      final form = _QuestionForm();
      form.textController.text = q.text;
      form.pointsController.text = q.points.toString();
      form.options = q.options.map((opt) => TextEditingController(text: opt)).toList();
      
      // Initialiser la réponse correcte en s'assurant qu'elle correspond à une option
      String correctAnswer = q.correctAnswer ?? '';
      if (correctAnswer.isNotEmpty) {
        // Vérifier si la réponse correspond exactement à une option
        final options = q.options.map((opt) => opt.trim()).toList();
        if (options.contains(correctAnswer.trim())) {
          form.correctAnswerController.text = correctAnswer;
        } else {
          // Essayer de trouver une correspondance insensible à la casse
          final normalizedCorrectAnswer = correctAnswer.toLowerCase().trim();
          bool found = false;
          for (var option in options) {
            if (option.toLowerCase().trim() == normalizedCorrectAnswer) {
              form.correctAnswerController.text = option; // Utiliser l'option exacte
              found = true;
              break;
            }
          }
          if (!found) {
            // Si aucune correspondance, utiliser la valeur originale
            form.correctAnswerController.text = correctAnswer;
          }
        }
      } else {
        form.correctAnswerController.text = '';
      }
      
      // Créer une clé pour cette question
      _questionKeys[index] = GlobalKey();
      
      return form;
    }).toList();

    if (_questions.isEmpty) {
      _addQuestion();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _passingScoreController.dispose();
    _maxAttemptsController.dispose();
    _scrollController.dispose();
    for (var q in _questions) {
      q.dispose();
    }
    super.dispose();
  }

  void _addQuestion() {
    setState(() {
      _questions.add(_QuestionForm());
      _questionKeys[_questions.length - 1] = GlobalKey();
    });
  }

  void _scrollToQuestion(int index) {
    final key = _questionKeys[index];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _removeQuestion(int index) {
    setState(() {
      _questions[index].dispose();
      _questions.removeAt(index);
      // Réorganiser les clés
      _questionKeys.clear();
      for (int i = 0; i < _questions.length; i++) {
        _questionKeys[i] = GlobalKey();
      }
    });
  }

  void _removeOption(int questionIndex, int optionIndex) {
    setState(() {
      final question = _questions[questionIndex];
      final removedOption = question.options[optionIndex].text.trim();
      final currentCorrectAnswer = question.correctAnswerController.text.trim();
      
      // Si l'option supprimée était la réponse correcte, la mettre à jour
      if (removedOption.isNotEmpty && 
          (removedOption == currentCorrectAnswer || 
           removedOption.toLowerCase() == currentCorrectAnswer.toLowerCase())) {
        // Filtrer les options restantes
        final remainingOptions = question.options
            .asMap()
            .entries
            .where((e) => e.key != optionIndex)
            .map((e) => e.value.text.trim())
            .where((opt) => opt.isNotEmpty)
            .toList();
        
        // Si des options restent, mettre la première comme réponse correcte par défaut
        if (remainingOptions.isNotEmpty) {
          question.correctAnswerController.text = remainingOptions.first;
        } else {
          // Sinon, vider la réponse correcte
          question.correctAnswerController.text = '';
        }
      }
      
      // Supprimer l'option
      question.options[optionIndex].dispose();
      question.options.removeAt(optionIndex);
    });
  }

  Future<void> _saveSingleQuestion(int questionIndex) async {
    final q = _questions[questionIndex];
    final questionText = q.textController.text.trim();
    
    // Validation de la question
    if (questionText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Question ${questionIndex + 1}: Le texte de la question est requis'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Filtrer les options vides
    final validOptions = q.options
        .map((opt) => opt.text.trim())
        .where((opt) => opt.isNotEmpty)
        .toList();
    
    if (validOptions.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Question ${questionIndex + 1}: Au moins 2 options valides sont requises'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    final correctAnswer = q.correctAnswerController.text.trim();
    if (correctAnswer.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Question ${questionIndex + 1}: La réponse correcte est requise'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Vérifier que la réponse correcte correspond à une option
    if (!validOptions.contains(correctAnswer)) {
      // Essayer de trouver une correspondance insensible à la casse
      final normalizedCorrectAnswer = correctAnswer.toLowerCase().trim();
      String? matchingOption;
      
      for (var option in validOptions) {
        if (option.toLowerCase().trim() == normalizedCorrectAnswer) {
          matchingOption = option;
          break;
        }
      }
      
      if (matchingOption == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Question ${questionIndex + 1}: La réponse correcte doit correspondre à une des options'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      } else {
        q.correctAnswerController.text = matchingOption;
      }
    }
    
    setState(() {
      _questionSaving[questionIndex] = true;
    });
    
    try {
      // Préparer les données de la question
      final questionData = {
        'text': questionText,
        'correctAnswer': q.correctAnswerController.text.trim(),
        'options': validOptions,
        'points': int.tryParse(q.pointsController.text) ?? 1,
      };
      
      // Mettre à jour toutes les questions du quiz
      final allQuestionsData = _questions.asMap().entries.map((entry) {
        final idx = entry.key;
        final question = entry.value;
        
        if (idx == questionIndex) {
          return questionData;
        }
        
        // Pour les autres questions, utiliser les données actuelles
        final otherValidOptions = question.options
            .map((opt) => opt.text.trim())
            .where((opt) => opt.isNotEmpty)
            .toList();
        
        return {
          'text': question.textController.text.trim(),
          'correctAnswer': question.correctAnswerController.text.trim(),
          'options': otherValidOptions,
          'points': int.tryParse(question.pointsController.text) ?? 1,
        };
      }).toList();
      
      // Enregistrer le quiz complet avec la question mise à jour
      final passingScore = int.tryParse(_passingScoreController.text) ?? widget.quiz.passingScore;
      final maxAttempts = int.tryParse(_maxAttemptsController.text) ?? widget.quiz.maxAttempts;
      final title = _titleController.text.trim();
      final description = _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim();

      if (widget.quiz.courseId != null) {
        await _quizService.updateCourseQuiz(
          courseId: widget.quiz.courseId!,
          title: title,
          description: description,
          passingScore: passingScore,
          maxAttempts: maxAttempts,
          level: _selectedLevel,
          questions: allQuestionsData,
        );
      } else {
        await _quizService.updateStandaloneQuiz(
          quizId: widget.quiz.id,
          title: title,
          description: description,
          passingScore: passingScore,
          maxAttempts: maxAttempts,
          level: _selectedLevel,
          questions: allQuestionsData,
        );
      }
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Question ${questionIndex + 1} enregistrée avec succès !'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'enregistrement: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _questionSaving[questionIndex] = false;
        });
      }
    }
  }

  void _showCorrectAnswers() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Les bonnes réponses'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _questions.length,
            itemBuilder: (context, index) {
              final q = _questions[index];
              final questionText = q.textController.text.trim();
              final correctAnswer = q.correctAnswerController.text.trim();
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Question ${index + 1}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      questionText.isEmpty ? '(Texte non renseigné)' : questionText,
                      style: TextStyle(
                        fontSize: 14,
                        color: questionText.isEmpty ? Colors.grey : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              correctAnswer.isEmpty 
                                  ? '(Réponse non renseignée)' 
                                  : correctAnswer,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: correctAnswer.isEmpty 
                                    ? Colors.grey 
                                    : Colors.green.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveQuiz() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Corriger automatiquement les réponses correctes avant validation
    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      
      // Filtrer les options vides
      final validOptions = q.options
          .map((opt) => opt.text.trim())
          .where((opt) => opt.isNotEmpty)
          .toList();
      
      if (validOptions.isEmpty) continue;
      
      final currentCorrectAnswer = q.correctAnswerController.text.trim();
      
      // Si la réponse correcte est vide, passer à la question suivante
      if (currentCorrectAnswer.isEmpty) continue;
      
      // Vérifier si la réponse correcte correspond à une option (exacte ou avec variations)
      bool foundExact = validOptions.contains(currentCorrectAnswer);
      
      if (!foundExact) {
        // Chercher une correspondance insensible à la casse
        final normalizedCorrectAnswer = currentCorrectAnswer.toLowerCase().trim();
        String? matchingOption;
        
        for (var option in validOptions) {
          if (option.toLowerCase().trim() == normalizedCorrectAnswer) {
            matchingOption = option;
            break;
          }
        }
        
        // Si on trouve une correspondance, mettre à jour automatiquement
        if (matchingOption != null) {
          q.correctAnswerController.text = matchingOption;
        }
      }
    }

    // Valider les questions après correction automatique
    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      final questionText = q.textController.text.trim();
      
      if (questionText.isEmpty) {
        _scrollToQuestion(i);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Question ${i + 1}: Le texte de la question est requis'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Voir',
              textColor: Colors.white,
              onPressed: () => _scrollToQuestion(i),
            ),
          ),
        );
        return;
      }
      
      // Filtrer les options vides et normaliser
      final validOptions = q.options
          .map((opt) => opt.text.trim())
          .where((opt) => opt.isNotEmpty)
          .toList();
      
      if (validOptions.length < 2) {
        _scrollToQuestion(i);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Question ${i + 1}: Au moins 2 options valides sont requises'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Voir',
              textColor: Colors.white,
              onPressed: () => _scrollToQuestion(i),
            ),
          ),
        );
        return;
      }
      
      final correctAnswer = q.correctAnswerController.text.trim();
      if (correctAnswer.isEmpty) {
        _scrollToQuestion(i);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Question ${i + 1}: La réponse correcte est requise. Veuillez copier une des options ci-dessus.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Voir',
              textColor: Colors.white,
              onPressed: () => _scrollToQuestion(i),
            ),
          ),
        );
        return;
      }
      
      // Vérifier que la réponse correcte correspond à une option
      if (!validOptions.contains(correctAnswer)) {
        _scrollToQuestion(i);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Question ${i + 1}: La réponse correcte doit correspondre exactement à une des options. Options disponibles: ${validOptions.join(", ")}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'Voir',
              textColor: Colors.white,
              onPressed: () => _scrollToQuestion(i),
            ),
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final questionsData = _questions.map((q) {
        // Filtrer les options vides avant l'envoi
        final validOptions = q.options
            .map((opt) => opt.text.trim())
            .where((opt) => opt.isNotEmpty)
            .toList();
        
        // S'assurer que la réponse correcte correspond exactement à une option
        final correctAnswer = q.correctAnswerController.text.trim();
        String finalCorrectAnswer = correctAnswer;
        
        // Si la réponse correcte ne correspond pas exactement, chercher une correspondance
        if (!validOptions.contains(correctAnswer)) {
          final normalizedCorrectAnswer = correctAnswer.toLowerCase().trim();
          for (var option in validOptions) {
            if (option.toLowerCase().trim() == normalizedCorrectAnswer) {
              finalCorrectAnswer = option; // Utiliser l'option exacte
              break;
            }
          }
        }
        
        return {
          'text': q.textController.text.trim(),
          'correctAnswer': finalCorrectAnswer,
          'options': validOptions,
          'points': int.tryParse(q.pointsController.text) ?? 1,
        };
      }).toList();

      // S'assurer que les valeurs requises sont présentes
      final passingScore = int.tryParse(_passingScoreController.text) ?? widget.quiz.passingScore;
      final maxAttempts = int.tryParse(_maxAttemptsController.text) ?? widget.quiz.maxAttempts;
      final title = _titleController.text.trim();
      final description = _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim();

      if (widget.quiz.courseId != null) {
        await _quizService.updateCourseQuiz(
          courseId: widget.quiz.courseId!,
          title: title,
          description: description,
          passingScore: passingScore,
          maxAttempts: maxAttempts,
          level: _selectedLevel,
          questions: questionsData,
        );
      } else {
        await _quizService.updateStandaloneQuiz(
          quizId: widget.quiz.id,
          title: title,
          description: description,
          passingScore: passingScore,
          maxAttempts: maxAttempts,
          level: _selectedLevel,
          questions: questionsData,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Quiz modifié avec succès !'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      
      String errorMessage = 'Erreur lors de la sauvegarde';
      final errorString = e.toString();
      
      if (errorString.contains('400')) {
        errorMessage = 'Données invalides. Vérifiez que tous les champs sont correctement remplis.';
      } else if (errorString.contains('401') || errorString.contains('403')) {
        errorMessage = 'Vous n\'êtes pas autorisé à modifier ce quiz.';
      } else if (errorString.contains('404')) {
        errorMessage = 'Quiz introuvable.';
      } else if (errorString.contains('500')) {
        errorMessage = 'Erreur serveur. Veuillez réessayer plus tard.';
      } else {
        errorMessage = 'Erreur : ${errorString.length > 100 ? errorString.substring(0, 100) + "..." : errorString}';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Modifier le quiz'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Titre du quiz *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedLevel,
                decoration: const InputDecoration(
                  labelText: 'Niveau *',
                  border: OutlineInputBorder(),
                ),
                items: _levels.map((level) {
                  return DropdownMenuItem(
                    value: level['value'],
                    child: Text(level['label']!),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedLevel = value!);
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _passingScoreController,
                      decoration: const InputDecoration(
                        labelText: 'Score minimum (%) *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        final score = int.tryParse(v ?? '');
                        if (score == null || score < 0 || score > 100) {
                          return 'Entre 0 et 100';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _maxAttemptsController,
                      decoration: const InputDecoration(
                        labelText: 'Tentatives max *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        final attempts = int.tryParse(v ?? '');
                        if (attempts == null || attempts < 1) {
                          return 'Au moins 1';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Questions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle),
                    onPressed: _addQuestion,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
              ..._questions.asMap().entries.map((entry) {
                final index = entry.key;
                final question = entry.value;
                return Card(
                  key: _questionKeys[index],
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Question ${index + 1}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            if (_questions.length > 1)
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _removeQuestion(index),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: question.textController,
                          decoration: const InputDecoration(
                            labelText: 'Texte de la question *',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 8),
                        ...question.options.asMap().entries.map((optEntry) {
                          final optIndex = optEntry.key;
                          final option = optEntry.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: option,
                                    decoration: InputDecoration(
                                      labelText: 'Option ${optIndex + 1}',
                                      border: const OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                if (question.options.length > 2)
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _removeOption(index, optIndex),
                                  ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              question.options.add(TextEditingController());
                            });
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Ajouter option'),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: question.correctAnswerController,
                                decoration: const InputDecoration(
                                  labelText: 'Réponse correcte *',
                                  border: OutlineInputBorder(),
                                  hintText: 'Copiez une des options ci-dessus',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.arrow_drop_down),
                              tooltip: 'Sélectionner une option',
                              onSelected: (value) {
                                question.correctAnswerController.text = value;
                                setState(() {});
                              },
                              itemBuilder: (context) {
                                final validOptions = question.options
                                    .map((opt) => opt.text.trim())
                                    .where((opt) => opt.isNotEmpty)
                                    .toList();
                                
                                if (validOptions.isEmpty) {
                                  return [
                                    const PopupMenuItem(
                                      enabled: false,
                                      child: Text('Aucune option disponible'),
                                    ),
                                  ];
                                }
                                
                                return validOptions.map((option) {
                                  return PopupMenuItem<String>(
                                    value: option,
                                    child: Text(option),
                                  );
                                }).toList();
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: question.pointsController,
                          decoration: const InputDecoration(
                            labelText: 'Points',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _questionSaving[index] == true 
                                ? null 
                                : () => _saveSingleQuestion(index),
                            icon: _questionSaving[index] == true
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.save),
                            label: Text(_questionSaving[index] == true 
                                ? 'Enregistrement...' 
                                : 'Enregistrer'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _showCorrectAnswers,
                  icon: const Icon(Icons.visibility),
                  label: const Text('Voir la bonne réponse'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuestionForm {
  final TextEditingController textController = TextEditingController();
  final TextEditingController correctAnswerController = TextEditingController();
  final TextEditingController pointsController = TextEditingController();
  List<TextEditingController> options = [TextEditingController(), TextEditingController()];

  void dispose() {
    textController.dispose();
    correctAnswerController.dispose();
    pointsController.dispose();
    for (var opt in options) {
      opt.dispose();
    }
  }
}

