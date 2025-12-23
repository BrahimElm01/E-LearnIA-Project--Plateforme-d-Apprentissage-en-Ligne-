import 'package:flutter/material.dart';
import '../services/course_service.dart';

class CreateStandaloneQuizScreen extends StatefulWidget {
  const CreateStandaloneQuizScreen({super.key});

  @override
  State<CreateStandaloneQuizScreen> createState() => _CreateStandaloneQuizScreenState();
}

class _CreateStandaloneQuizScreenState extends State<CreateStandaloneQuizScreen> {
  final CourseService _courseService = CourseService();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _passingScoreController = TextEditingController();
  final _maxAttemptsController = TextEditingController();

  List<_QuestionForm> _questions = [];
  String _selectedLevel = 'BEGINNER';
  bool _isLoading = false;

  final List<Map<String, String>> _levels = [
    {'value': 'BEGINNER', 'label': 'Débutant'},
    {'value': 'INTERMEDIATE', 'label': 'Intermédiaire'},
    {'value': 'ADVANCED', 'label': 'Avancé'},
  ];

  @override
  void initState() {
    super.initState();
    _passingScoreController.text = '75';
    _maxAttemptsController.text = '3';
    _addQuestion();
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

      await _courseService.createStandaloneQuiz(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        passingScore: int.tryParse(_passingScoreController.text),
        maxAttempts: int.tryParse(_maxAttemptsController.text),
        level: _selectedLevel,
        questions: questionsData,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Quiz créé avec succès !'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : $e'),
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
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Créer un quiz'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
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
                                    onPressed: () {
                                      setState(() {
                                        option.dispose();
                                        question.options.removeAt(optIndex);
                                      });
                                    },
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
                        TextFormField(
                          controller: question.correctAnswerController,
                          decoration: const InputDecoration(
                            labelText: 'Réponse correcte *',
                            border: OutlineInputBorder(),
                            hintText: 'Copiez une des options ci-dessus',
                          ),
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
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveQuiz,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Créer le quiz'),
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
  final List<TextEditingController> options = [
    TextEditingController(),
    TextEditingController(),
  ];

  void dispose() {
    textController.dispose();
    correctAnswerController.dispose();
    pointsController.dispose();
    for (var opt in options) {
      opt.dispose();
    }
  }
}

