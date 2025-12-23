import 'package:flutter/material.dart';
import '../services/course_service.dart';
import '../models/quiz.dart';

class CreateQuizScreen extends StatefulWidget {
  final int courseId;
  final String courseTitle;
  final Quiz? existingQuiz; // Si présent, on est en mode édition

  const CreateQuizScreen({
    super.key,
    required this.courseId,
    required this.courseTitle,
    this.existingQuiz,
  });

  @override
  State<CreateQuizScreen> createState() => _CreateQuizScreenState();
}

class _CreateQuizScreenState extends State<CreateQuizScreen> {
  final CourseService _courseService = CourseService();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _passingScoreController = TextEditingController();
  final _maxAttemptsController = TextEditingController();

  List<_QuestionForm> _questions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingQuiz != null) {
      // Mode édition
      _titleController.text = widget.existingQuiz!.title;
      _descriptionController.text = widget.existingQuiz!.description ?? '';
      _passingScoreController.text = widget.existingQuiz!.passingScore.toString();
      _maxAttemptsController.text = widget.existingQuiz!.maxAttempts.toString();
      _questions = widget.existingQuiz!.questions.map((q) {
        // Utiliser correctAnswer si disponible, sinon prendre la première option
        String correctAnswer;
        if (q.correctAnswer != null && q.correctAnswer!.isNotEmpty) {
          correctAnswer = q.correctAnswer!;
        } else if (q.options.isNotEmpty) {
          correctAnswer = q.options[0];
        } else {
          correctAnswer = '';
        }
        return _QuestionForm(
          text: q.text,
          correctAnswer: correctAnswer,
          options: List.from(q.options),
          points: q.points,
        );
      }).toList();
    } else {
      // Mode création - ajouter une question par défaut
      _addQuestion();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _passingScoreController.dispose();
    _maxAttemptsController.dispose();
    for (var q in _questions) {
      q.dispose();
    }
    super.dispose();
  }

  void _addQuestion() {
    setState(() {
      _questions.add(_QuestionForm());
    });
  }

  void _removeQuestion(int index) {
    setState(() {
      _questions[index].dispose();
      _questions.removeAt(index);
    });
  }

  Future<void> _saveQuiz() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Valider les questions
    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      if (q.textController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Question ${i + 1}: Le texte est requis')),
        );
        return;
      }
      if (q.options.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Question ${i + 1}: Au moins 2 options sont requises')),
        );
        return;
      }
      if (q.correctAnswerController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Question ${i + 1}: La réponse correcte est requise')),
        );
        return;
      }
      // Vérifier que la réponse correcte est dans les options
      if (!q.options.contains(q.correctAnswerController.text.trim())) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Question ${i + 1}: La réponse correcte doit être une des options')),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final questionsData = _questions.map((q) {
        return {
          'text': q.textController.text.trim(),
          'correctAnswer': q.correctAnswerController.text.trim(),
          'options': q.options,
          'points': int.tryParse(q.pointsController.text) ?? 1,
        };
      }).toList();

      if (widget.existingQuiz != null) {
        // Mode édition
        await _courseService.updateQuiz(
          courseId: widget.courseId,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          passingScore: int.tryParse(_passingScoreController.text),
          maxAttempts: int.tryParse(_maxAttemptsController.text),
          questions: questionsData,
        );
      } else {
        // Mode création
        await _courseService.createQuiz(
          courseId: widget.courseId,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          passingScore: int.tryParse(_passingScoreController.text),
          maxAttempts: int.tryParse(_maxAttemptsController.text),
          questions: questionsData,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.existingQuiz != null
              ? 'Quiz modifié avec succès'
              : 'Quiz créé avec succès'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingQuiz != null ? 'Modifier le Quiz' : 'Créer un Quiz'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Informations générales
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Informations générales',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Titre du quiz *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Le titre est requis';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description (optionnel)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _passingScoreController,
                            decoration: const InputDecoration(
                              labelText: 'Score minimum (%)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                final score = int.tryParse(value);
                                if (score == null || score < 0 || score > 100) {
                                  return 'Score entre 0 et 100';
                                }
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
                              labelText: 'Tentatives max',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                final attempts = int.tryParse(value);
                                if (attempts == null || attempts < 1) {
                                  return 'Au moins 1 tentative';
                                }
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Questions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Questions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _addQuestion,
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...List.generate(_questions.length, (index) {
              return _QuestionCard(
                question: _questions[index],
                questionNumber: index + 1,
                onRemove: _questions.length > 1 ? () => _removeQuestion(index) : null,
              );
            }),
            const SizedBox(height: 24),

            // Bouton de sauvegarde
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveQuiz,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(widget.existingQuiz != null
                        ? 'Enregistrer les modifications'
                        : 'Créer le quiz'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _QuestionForm {
  final TextEditingController textController = TextEditingController();
  final TextEditingController correctAnswerController = TextEditingController();
  final TextEditingController pointsController = TextEditingController();
  List<String> options = [];
  String? _initialCorrectAnswer;

  _QuestionForm({
    String? text,
    String? correctAnswer,
    List<String>? options,
    int? points,
  }) {
    if (text != null) textController.text = text;
    if (correctAnswer != null) {
      correctAnswerController.text = correctAnswer;
      _initialCorrectAnswer = correctAnswer;
    }
    if (options != null) this.options = List.from(options);
    if (points != null) pointsController.text = points.toString();
    if (pointsController.text.isEmpty) pointsController.text = '1';
  }

  String get text => textController.text.trim();
  String get correctAnswer => correctAnswerController.text.trim();
  int get points => int.tryParse(pointsController.text) ?? 1;

  void dispose() {
    textController.dispose();
    correctAnswerController.dispose();
    pointsController.dispose();
  }
}

class _QuestionCard extends StatefulWidget {
  final _QuestionForm question;
  final int questionNumber;
  final VoidCallback? onRemove;

  const _QuestionCard({
    required this.question,
    required this.questionNumber,
    this.onRemove,
  });

  @override
  State<_QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<_QuestionCard> {
  final TextEditingController _optionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialiser les options si elles existent déjà
    if (widget.question.options.isEmpty && widget.question._initialCorrectAnswer != null) {
      widget.question.options.add(widget.question._initialCorrectAnswer!);
    }
  }

  @override
  void dispose() {
    _optionController.dispose();
    super.dispose();
  }

  void _addOption() {
    final option = _optionController.text.trim();
    if (option.isNotEmpty && !widget.question.options.contains(option)) {
      setState(() {
        widget.question.options.add(option);
        _optionController.clear();
      });
    }
  }

  void _removeOption(String option) {
    setState(() {
      widget.question.options.remove(option);
      if (widget.question.correctAnswerController.text == option) {
        widget.question.correctAnswerController.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
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
                  'Question ${widget.questionNumber}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.onRemove != null)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: widget.onRemove,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: widget.question.textController,
              decoration: const InputDecoration(
                labelText: 'Texte de la question *',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _optionController,
                    decoration: const InputDecoration(
                      labelText: 'Nouvelle option',
                      border: OutlineInputBorder(),
                      hintText: 'Entrez une option...',
                    ),
                    onFieldSubmitted: (_) => _addOption(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addOption,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Ajouter'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (widget.question.options.isNotEmpty) ...[
              const Text(
                'Options:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.question.options.map((option) {
                  return Chip(
                    label: Text(option),
                    onDeleted: () => _removeOption(option),
                    deleteIcon: const Icon(Icons.close, size: 18),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: widget.question.correctAnswerController,
              decoration: InputDecoration(
                labelText: 'Réponse correcte *',
                border: const OutlineInputBorder(),
                hintText: widget.question.options.isNotEmpty
                    ? 'Choisissez parmi: ${widget.question.options.join(", ")}'
                    : 'Entrez la réponse correcte',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: widget.question.pointsController,
              decoration: const InputDecoration(
                labelText: 'Points',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
    );
  }
}

