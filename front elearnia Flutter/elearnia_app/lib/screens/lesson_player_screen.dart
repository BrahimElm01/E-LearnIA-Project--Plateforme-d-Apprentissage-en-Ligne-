// lib/screens/lesson_player_screen.dart
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/progress_service.dart';
import '../services/course_service.dart';

class LessonPlayerScreen extends StatefulWidget {
  final int courseId;
  final int lessonId;
  final int lessonIndex; // Index de la leçon dans la liste (0-based)
  final String courseTitle;
  final String lessonTitle;
  final String duration;
  final String? videoUrl;
  final String? description;
  final int totalLessons; // Nombre total de leçons dans le cours

  const LessonPlayerScreen({
    super.key,
    required this.courseId,
    required this.lessonId,
    required this.lessonIndex,
    required this.courseTitle,
    required this.lessonTitle,
    required this.duration,
    this.videoUrl,
    this.description,
    required this.totalLessons,
  });

  @override
  State<LessonPlayerScreen> createState() => _LessonPlayerScreenState();
}

class _LessonPlayerScreenState extends State<LessonPlayerScreen> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  YoutubePlayerController? _youtubeController;
  bool _isLoading = true;
  String? _error;
  bool _isYouTube = false;
  bool _isCompleted = false;
  final ProgressService _progressService = ProgressService();

  @override
  void initState() {
    super.initState();
    if (widget.videoUrl != null && widget.videoUrl!.isNotEmpty) {
      _initializePlayer();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsCompleted() async {
    if (_isCompleted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Récupérer la progression actuelle du cours
      final courseService = CourseService();
      final courses = await courseService.getStudentCourses();
      final currentCourse = courses.firstWhere(
        (c) => c.id == widget.courseId,
        orElse: () => throw Exception('Cours non trouvé'),
      );

      // Calculer la progression : on suppose que les leçons sont complétées dans l'ordre
      // Si l'étudiant complète la leçon à l'index N, cela signifie qu'il a complété N+1 leçons
      // La progression est : (leçons complétées / total leçons) * 100
      final lessonsCompleted = widget.lessonIndex + 1;
      final newProgress = ((lessonsCompleted / widget.totalLessons) * 100).clamp(0.0, 100.0);
      
      // Le cours est complété si toutes les leçons sont complétées
      final isCourseCompleted = lessonsCompleted >= widget.totalLessons;

      // Si la nouvelle progression est supérieure à l'actuelle, on la met à jour
      // Sinon, on garde la progression actuelle (pour éviter de réduire la progression)
      final finalProgress = newProgress > currentCourse.progress ? newProgress : currentCourse.progress;

      await _progressService.updateProgress(
        courseId: widget.courseId,
        progress: finalProgress,
        completed: isCourseCompleted,
      );

      if (!mounted) return;
      setState(() {
        _isCompleted = true;
        _isLoading = false;
      });

      final message = isCourseCompleted
          ? '🎉 Félicitations ! Cours terminé à 100% !'
          : 'Leçon marquée comme complétée ✓\nProgression: ${finalProgress.toStringAsFixed(0)}%';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

      // Retourner true pour indiquer que la leçon est complétée
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la mise à jour: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _initializePlayer() {
    final url = widget.videoUrl!;
    
    // Détecter si c'est une URL YouTube
    if (_isYouTubeUrl(url)) {
      _initializeYouTubePlayer(url);
    } else if (_isUploadedVideoUrl(url)) {
      // C'est une vidéo uploadée, utiliser le lecteur vidéo standard
      _initializeVideoPlayer(url);
    } else {
      // Autre type d'URL (peut-être une URL directe), essayer le lecteur vidéo
      _initializeVideoPlayer(url);
    }
  }

  bool _isYouTubeUrl(String url) {
    return url.contains('youtube.com') || 
           url.contains('youtu.be') || 
           url.contains('youtube-nocookie.com');
  }

  bool _isUploadedVideoUrl(String url) {
    // Détecter si c'est une vidéo uploadée (contient /api/files/videos/)
    return url.contains('/api/files/videos/') ||
           url.contains('localhost:8080/api/files/videos/') ||
           url.contains('192.168.100.231:8080/api/files/videos/') ||
           url.contains('127.0.0.1:8080/api/files/videos/');
  }

  void _initializeYouTubePlayer(String url) {
    try {
      String? videoId;
      
      // Vérifier si c'est une URL de recherche YouTube (results?search_query=)
      if (url.contains('youtube.com/results') || url.contains('search_query')) {
        // Pour les URLs de recherche, on ne peut pas extraire directement l'ID
        // On affiche un message d'erreur avec une option pour ouvrir dans le navigateur
        setState(() {
          _error = 'Cette URL est une recherche YouTube. Veuillez utiliser une URL de vidéo directe.';
          _isLoading = false;
        });
        return;
      }
      
      // Extraire l'ID de la vidéo YouTube pour différents formats
      if (url.contains('youtu.be/')) {
        // Format: https://youtu.be/VIDEO_ID
        videoId = url.split('youtu.be/')[1].split('?')[0].split('/')[0];
      } else if (url.contains('youtube.com/watch?v=')) {
        // Format: https://www.youtube.com/watch?v=VIDEO_ID
        videoId = url.split('v=')[1].split('&')[0].split('#')[0];
      } else if (url.contains('youtube.com/embed/')) {
        // Format: https://www.youtube.com/embed/VIDEO_ID
        videoId = url.split('embed/')[1].split('?')[0].split('/')[0];
      } else if (url.contains('youtube.com/v/')) {
        // Format: https://www.youtube.com/v/VIDEO_ID
        videoId = url.split('v/')[1].split('?')[0].split('/')[0];
      } else if (url.contains('youtube-nocookie.com/embed/')) {
        // Format: https://www.youtube-nocookie.com/embed/VIDEO_ID
        videoId = url.split('embed/')[1].split('?')[0].split('/')[0];
      }

      // Nettoyer l'ID de la vidéo (enlever les caractères invalides)
      if (videoId != null) {
        videoId = videoId.trim();
        // Vérifier que l'ID ne contient que des caractères valides pour un ID YouTube
        if (videoId.length < 11 || !RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(videoId)) {
          // Si l'ID n'est pas valide, essayer de l'extraire différemment
          final regex = RegExp(r'(?:youtube\.com\/watch\?v=|youtu\.be\/|youtube\.com\/embed\/)([a-zA-Z0-9_-]{11})');
          final match = regex.firstMatch(url);
          if (match != null && match.groupCount >= 1) {
            videoId = match.group(1);
          } else {
            videoId = null;
          }
        }
      }

      if (videoId != null && videoId.isNotEmpty && videoId.length == 11) {
        _youtubeController = YoutubePlayerController(
          initialVideoId: videoId,
          flags: const YoutubePlayerFlags(
            autoPlay: true,
            mute: false,
            enableCaption: true,
            hideControls: false,
            controlsVisibleAtStart: true,
          ),
        );
        
        setState(() {
          _isYouTube = true;
          _isLoading = false;
        });
      } else {
        // Si on ne peut pas extraire l'ID, afficher un message d'erreur
        setState(() {
          _error = 'Impossible d\'extraire l\'ID de la vidéo YouTube. Veuillez vérifier l\'URL.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erreur lors du chargement de la vidéo YouTube: $e';
        _isLoading = false;
      });
    }
  }

  void _initializeVideoPlayer(String url) {
    try {
      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(url),
      );

      _videoPlayerController!.initialize().then((_) {
        _chewieController = ChewieController(
          videoPlayerController: _videoPlayerController!,
          autoPlay: true,
          looping: false,
          aspectRatio: _videoPlayerController!.value.aspectRatio,
          errorBuilder: (context, errorMessage) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.white, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    errorMessage,
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _openInBrowser(url),
                    child: const Text('Ouvrir dans le navigateur'),
                  ),
                ],
              ),
            );
          },
        );

        setState(() {
          _isLoading = false;
        });
      }).catchError((error) {
        setState(() {
          _error = 'Erreur lors du chargement de la vidéo: $error';
          _isLoading = false;
        });
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _openInBrowser(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible d\'ouvrir: $url')),
        );
      }
    }
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    _youtubeController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFFF4F4F4);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.courseTitle,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // =================== VIDEO PLAYER ===================
            Container(
              width: double.infinity,
              height: 220,
              color: Colors.black,
              child: _buildVideoPlayer(),
            ),

            // =================== CONTENU SCROLLABLE ===================
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titre + durée
                    Text(
                      widget.lessonTitle,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.duration,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Description
                    if (widget.description != null && widget.description!.isNotEmpty) ...[
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.description!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    const SizedBox(height: 20),

                    // Resources
                    const Text(
                      'Resources',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _ResourceTile(
                      icon: Icons.picture_as_pdf_rounded,
                      title: 'Lesson Slides',
                      subtitle: 'PDF file with slides',
                      onTap: () {
                        // plus tard : ouvrir / télécharger le PDF
                      },
                    ),
                    const SizedBox(height: 8),
                    _ResourceTile(
                      icon: Icons.folder_zip_rounded,
                      title: 'Exercise Files',
                      subtitle: 'Download starter project',
                      onTap: () {
                        // plus tard : ouvrir / télécharger le ZIP
                      },
                    ),
                  ],
                ),
              ),
            ),

            // =================== BOUTON COMPLETED ===================
            SafeArea(
              top: false,
              child: Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onPressed: _isCompleted ? null : _markAsCompleted,
                    icon: Icon(_isCompleted ? Icons.check_circle : Icons.check_circle_outline),
                    label: Text(
                      _isCompleted ? 'Leçon complétée' : 'Marquer comme complétée',
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (widget.videoUrl == null || widget.videoUrl!.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.play_circle_fill_rounded,
              color: Colors.white,
              size: 72,
            ),
            SizedBox(height: 16),
            Text(
              'Aucune vidéo disponible',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 48,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            // Afficher le bouton "Ouvrir dans le navigateur" seulement si c'est une URL valide
            if (widget.videoUrl != null && 
                (widget.videoUrl!.contains('youtube.com') || 
                 widget.videoUrl!.contains('youtu.be')))
              ElevatedButton(
                onPressed: () => _openInBrowser(widget.videoUrl!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Ouvrir dans YouTube'),
              ),
          ],
        ),
      );
    }

    if (_isYouTube && _youtubeController != null) {
      return YoutubePlayerBuilder(
        onExitFullScreen: () {
          // Gérer la sortie du plein écran
        },
        player: YoutubePlayer(
          controller: _youtubeController!,
          showVideoProgressIndicator: true,
          progressIndicatorColor: Colors.blue,
          progressColors: const ProgressBarColors(
            playedColor: Colors.blue,
            handleColor: Colors.blueAccent,
          ),
          onReady: () {
            // Vérifier si la vidéo est prête
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onEnded: (metadata) {
            // Vidéo terminée
          },
        ),
        builder: (context, player) {
          return player;
        },
      );
    }

    if (_chewieController != null && _videoPlayerController != null) {
      return Chewie(controller: _chewieController!);
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.play_circle_fill_rounded,
            color: Colors.white,
            size: 72,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _openInBrowser(widget.videoUrl!),
            child: const Text('Ouvrir la vidéo'),
          ),
        ],
      ),
    );
  }
}

// =================== WIDGET RESOURCE TILE ===================

class _ResourceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ResourceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey.shade200,
              child: Icon(icon, color: Colors.black),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.download_rounded),
          ],
        ),
      ),
    );
  }
}
