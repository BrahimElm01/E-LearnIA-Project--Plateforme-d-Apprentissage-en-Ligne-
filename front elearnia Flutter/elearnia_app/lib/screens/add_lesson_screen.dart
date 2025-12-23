import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/course_service.dart';
import '../services/file_upload_service.dart';
import '../models/lesson.dart';

class AddLessonScreen extends StatefulWidget {
  final int courseId;

  const AddLessonScreen({
    super.key,
    required this.courseId,
  });

  @override
  State<AddLessonScreen> createState() => _AddLessonScreenState();
}

class _AddLessonScreenState extends State<AddLessonScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _videoUrlController = TextEditingController();
  final _durationController = TextEditingController();
  final _orderIndexController = TextEditingController();
  final CourseService _courseService = CourseService();
  final FileUploadService _fileUploadService = FileUploadService();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isLoading = false;
  bool _isUploadingVideo = false;
  String? _selectedVideoPath;
  File? _selectedVideoFile;
  String _videoSourceType = 'youtube'; // 'youtube' ou 'upload'

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _videoUrlController.dispose();
    _durationController.dispose();
    _orderIndexController.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
      );

      if (video != null) {
        setState(() {
          _selectedVideoFile = File(video.path);
          _selectedVideoPath = video.path;
          _videoUrlController.clear(); // Réinitialiser l'URL YouTube
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sélection de la vidéo : $e'),
          ),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Valider selon le type de source vidéo
    if (_videoSourceType == 'youtube') {
      if (_videoUrlController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez entrer une URL YouTube ou sélectionner un fichier vidéo'),
          ),
        );
        return;
      }
    } else {
      if (_selectedVideoFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez sélectionner un fichier vidéo'),
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      String? videoUrl;

      // Si on upload une vidéo, l'uploader d'abord
      if (_videoSourceType == 'upload' && _selectedVideoFile != null) {
        setState(() => _isUploadingVideo = true);
        try {
          videoUrl = await _fileUploadService.uploadVideo(_selectedVideoFile!);
          if (videoUrl == null || videoUrl.isEmpty) {
            throw Exception('L\'URL de la vidéo est vide après l\'upload');
          }
        } catch (e) {
          if (!mounted) return;
          setState(() {
            _isLoading = false;
            _isUploadingVideo = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de l\'upload de la vidéo : $e'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        setState(() => _isUploadingVideo = false);
      } else {
        // Utiliser l'URL YouTube
        videoUrl = _videoUrlController.text.trim();
      }

      await _courseService.createLesson(
        courseId: widget.courseId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        videoUrl: videoUrl!,
        duration: _durationController.text.trim().isEmpty
            ? null
            : int.tryParse(_durationController.text.trim()),
        orderIndex: int.parse(_orderIndexController.text.trim()),
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Leçon ajoutée avec succès 🎉'),
        ),
      );

      Navigator.of(context).pop(true); // retour avec succès
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'ajout de la leçon : $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFFF5F5F5);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        title: const Text(
          'Ajouter une vidéo',
          style: TextStyle(color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Titre de la leçon *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Titre obligatoire';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description (optionnel)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                // Sélecteur de source vidéo
                const Text(
                  'Source de la vidéo *',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _videoSourceType = 'youtube';
                            _selectedVideoFile = null;
                            _selectedVideoPath = null;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                          decoration: BoxDecoration(
                            color: _videoSourceType == 'youtube' 
                                ? Colors.blue.withOpacity(0.1) 
                                : Colors.grey.withOpacity(0.1),
                            border: Border.all(
                              color: _videoSourceType == 'youtube' 
                                  ? Colors.blue 
                                  : Colors.grey,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.play_circle_outline,
                                color: _videoSourceType == 'youtube' 
                                    ? Colors.blue 
                                    : Colors.grey,
                                size: 20,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'YouTube',
                                  style: TextStyle(
                                    fontWeight: _videoSourceType == 'youtube' 
                                        ? FontWeight.bold 
                                        : FontWeight.normal,
                                    color: _videoSourceType == 'youtube' 
                                        ? Colors.blue 
                                        : Colors.grey[700],
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _videoSourceType = 'upload';
                            _videoUrlController.clear();
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                          decoration: BoxDecoration(
                            color: _videoSourceType == 'upload' 
                                ? Colors.green.withOpacity(0.1) 
                                : Colors.grey.withOpacity(0.1),
                            border: Border.all(
                              color: _videoSourceType == 'upload' 
                                  ? Colors.green 
                                  : Colors.grey,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.upload_file,
                                color: _videoSourceType == 'upload' 
                                    ? Colors.green 
                                    : Colors.grey,
                                size: 20,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Depuis l\'appareil',
                                  style: TextStyle(
                                    fontWeight: _videoSourceType == 'upload' 
                                        ? FontWeight.bold 
                                        : FontWeight.normal,
                                    color: _videoSourceType == 'upload' 
                                        ? Colors.green 
                                        : Colors.grey[700],
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Champ selon le type de source
                if (_videoSourceType == 'youtube') ...[
                  TextFormField(
                    controller: _videoUrlController,
                    decoration: const InputDecoration(
                      labelText: 'URL de la vidéo YouTube *',
                      hintText: 'https://youtube.com/watch?v=...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.link),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'URL de la vidéo obligatoire';
                      }
                      return null;
                    },
                  ),
                ] else ...[
                  // Upload de vidéo
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _pickVideo,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _selectedVideoFile != null 
                              ? Colors.green 
                              : Colors.grey,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: _selectedVideoFile != null 
                            ? Colors.green.withOpacity(0.05) 
                            : Colors.grey.withOpacity(0.05),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            _selectedVideoFile != null 
                                ? Icons.check_circle 
                                : Icons.video_library,
                            size: 48,
                            color: _selectedVideoFile != null 
                                ? Colors.green 
                                : Colors.grey[600],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _selectedVideoFile != null 
                                ? 'Vidéo sélectionnée' 
                                : 'Appuyez pour sélectionner une vidéo',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: _selectedVideoFile != null 
                                  ? Colors.green 
                                  : Colors.grey[700],
                            ),
                          ),
                          if (_selectedVideoPath != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.insert_drive_file,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      _selectedVideoPath!.split('/').last,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_selectedVideoFile != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                '${(_selectedVideoFile!.lengthSync() / 1024 / 1024).toStringAsFixed(2)} MB',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (_isUploadingVideo) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          const LinearProgressIndicator(),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Upload en cours...',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _durationController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Durée (minutes)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _orderIndexController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Ordre *',
                          hintText: '1, 2, 3...',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Ordre obligatoire';
                          }
                          if (int.tryParse(value.trim()) == null) {
                            return 'Nombre invalide';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: (_isLoading || _isUploadingVideo) ? null : _submit,
                    child: (_isLoading || _isUploadingVideo)
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : Text(_isUploadingVideo ? 'Upload en cours...' : 'Ajouter la vidéo'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


