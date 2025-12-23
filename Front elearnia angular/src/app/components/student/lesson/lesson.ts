import { Component, OnInit, signal } from '@angular/core';
import { CommonModule, DatePipe } from '@angular/common';
import { FormBuilder, FormGroup, Validators, ReactiveFormsModule } from '@angular/forms';
import { ActivatedRoute, Router, RouterModule } from '@angular/router';
import { DomSanitizer, SafeResourceUrl } from '@angular/platform-browser';
import { CourseService } from '../../../services/course.service';
import { QuizService } from '../../../services/quiz.service';
import { Lesson } from '../../../models/lesson.model';
import { Quiz, Question } from '../../../models/quiz.model';

@Component({
  selector: 'app-lesson',
  standalone: true,
  imports: [CommonModule, RouterModule, ReactiveFormsModule, DatePipe],
  templateUrl: './lesson.html',
  styleUrl: './lesson.css'
})
export class LessonComponent implements OnInit {
  courseId = signal<number | null>(null);
  lessonId = signal<number | null>(null);
  lesson = signal<Lesson | null>(null);
  quiz = signal<Quiz | null>(null);
  isLoading = signal(false);
  errorMessage = signal<string | null>(null);
  isLastLesson = signal<boolean>(false);
  allLessons = signal<Lesson[]>([]);
  videoSafeUrl = signal<SafeResourceUrl | null>(null);
  isUploadedVideo = signal<boolean>(false);
  uploadedVideoUrl = signal<string | null>(null);
  reviews = signal<any[]>([]);
  reviewForm!: FormGroup;
  isSubmittingReview = signal<boolean>(false);
  showReviewForm = signal<boolean>(false);
  isEnrolled = signal<boolean>(true); // Supposé inscrit si on peut voir la leçon

  constructor(
    private route: ActivatedRoute,
    private router: Router,
    private courseService: CourseService,
    private quizService: QuizService,
    private sanitizer: DomSanitizer,
    private fb: FormBuilder
  ) {
    this.initReviewForm();
  }

  initReviewForm(): void {
    this.reviewForm = this.fb.group({
      rating: [5, [Validators.required, Validators.min(1), Validators.max(5)]],
      comment: ['', [Validators.required, Validators.minLength(10)]]
    });
  }

  ngOnInit(): void {
    const courseIdParam = this.route.snapshot.paramMap.get('courseId');
    const lessonIdParam = this.route.snapshot.paramMap.get('lessonId');

    if (!courseIdParam || !lessonIdParam) {
      this.errorMessage.set('Paramètres invalides');
      return;
    }

    const courseId = Number(courseIdParam);
    const lessonId = Number(lessonIdParam);

    if (isNaN(courseId) || isNaN(lessonId)) {
      this.errorMessage.set('ID invalide');
      return;
    }

    this.courseId.set(courseId);
    this.lessonId.set(lessonId);
    this.loadLesson();
  }

  loadLesson(): void {
    if (!this.courseId() || !this.lessonId()) return;

    this.isLoading.set(true);
    this.errorMessage.set(null);

    this.courseService.getCourseLessons(this.courseId()!).subscribe({
      next: (lessons) => {
        this.allLessons.set(lessons);
        const lesson = lessons.find(l => l.id === this.lessonId());
        if (lesson) {
          this.lesson.set(lesson);
          
          // Préparer l'URL de la vidéo
          if (lesson.videoUrl) {
            try {
              // Vérifier si c'est une vidéo uploadée (commence par /api/files/videos/ ou contient localhost:8080/api/files/videos/)
              if (this.isUploadedVideoUrl(lesson.videoUrl)) {
                // C'est une vidéo uploadée, utiliser la balise <video>
                this.isUploadedVideo.set(true);
                const normalizedUrl = this.normalizeVideoUrl(lesson.videoUrl);
                this.uploadedVideoUrl.set(normalizedUrl);
                this.videoSafeUrl.set(null);
                console.log('Uploaded video detected:', normalizedUrl);
              } else {
                // C'est une URL YouTube, utiliser l'iframe
                this.isUploadedVideo.set(false);
                this.uploadedVideoUrl.set(null);
                const embedUrl = this.getYouTubeEmbedUrl(lesson.videoUrl);
                if (embedUrl && embedUrl.includes('youtube.com/embed/')) {
                  // Valider que l'URL est correctement formatée avant de la sanitizer
                  const videoIdMatch = embedUrl.match(/embed\/([a-zA-Z0-9_-]{11})/);
                  if (videoIdMatch && videoIdMatch[1]) {
                    // URL valide, la sanitizer
                    this.videoSafeUrl.set(this.sanitizer.bypassSecurityTrustResourceUrl(embedUrl));
                  } else {
                    console.error('Invalid YouTube embed URL format:', embedUrl);
                    this.videoSafeUrl.set(null);
                  }
                } else {
                  // URL non-YouTube ou format non reconnu
                  console.warn('Video URL is not a recognized YouTube format:', lesson.videoUrl);
                  this.videoSafeUrl.set(null);
                }
              }
            } catch (error) {
              console.error('Error processing video URL:', error);
              this.videoSafeUrl.set(null);
              this.isUploadedVideo.set(false);
              this.uploadedVideoUrl.set(null);
            }
          } else {
            this.videoSafeUrl.set(null);
            this.isUploadedVideo.set(false);
            this.uploadedVideoUrl.set(null);
          }
          
          // Charger le quiz de cette leçon
          this.loadQuiz();
          // Charger les reviews du cours
          this.loadReviews(this.courseId()!);
        } else {
          this.errorMessage.set('Leçon introuvable');
        }
        this.isLoading.set(false);
      },
      error: (error: any) => {
        console.error('Error loading lesson', error);
        if (error.status === 404) {
          this.errorMessage.set('Leçon introuvable');
        } else if (error.status === 403) {
          this.errorMessage.set('Vous n\'êtes pas autorisé à voir cette leçon');
        } else {
          this.errorMessage.set('Erreur lors du chargement de la leçon');
        }
        this.isLoading.set(false);
      }
    });
  }

  loadQuiz(): void {
    if (!this.courseId() || !this.lessonId()) return;

    this.courseService.getLessonQuiz(this.courseId()!, this.lessonId()!).subscribe({
      next: (quiz) => {
        console.log('Lesson quiz loaded:', quiz);
        if (quiz && quiz.id) {
          this.quiz.set(quiz);
        } else {
          console.warn('Quiz loaded but invalid:', quiz);
          this.quiz.set(null);
        }
      },
      error: (error: any) => {
        console.error('Error loading lesson quiz', error);
        console.error('Error details:', {
          status: error.status,
          message: error.message,
          error: error.error
        });
        // Mettre quiz à null pour ne pas afficher la section
        this.quiz.set(null);
        
        // Afficher un message seulement si ce n'est pas une erreur 404 (quiz n'existe pas)
        if (error.status !== 404) {
          console.warn('Error loading quiz:', error.status, error.message);
        } else {
          console.log('No quiz found for this lesson (404)');
        }
      }
    });
  }


  navigateBack(): void {
    if (this.courseId()) {
      this.router.navigate(['/student/course', this.courseId()]);
    } else {
      this.router.navigate(['/student/courses']);
    }
  }

  isUploadedVideoUrl(videoUrl: string): boolean {
    if (!videoUrl) return false;
    // Vérifier si l'URL pointe vers notre endpoint de vidéos uploadées
    return videoUrl.includes('/api/files/videos/') || 
           videoUrl.includes('localhost:8080/api/files/videos/') ||
           videoUrl.includes('192.168.100.231:8080/api/files/videos/') ||
           videoUrl.includes('127.0.0.1:8080/api/files/videos/');
  }

  normalizeVideoUrl(videoUrl: string): string {
    if (!videoUrl) return '';
    // Normaliser l'URL pour utiliser localhost si on est en développement
    // ou garder l'IP si c'est pour un accès réseau
    if (videoUrl.includes('192.168.100.231:8080')) {
      // Remplacer par localhost si on est en développement local
      // Sinon garder l'IP pour l'accès réseau
      return videoUrl;
    }
    return videoUrl;
  }

  getYouTubeEmbedUrl(videoUrl: string): string {
    if (!videoUrl) return '';
    
    try {
      // Nettoyer l'URL (enlever les espaces, etc.)
      let cleanUrl = videoUrl.trim();
      
      // Extraire l'ID de la vidéo YouTube depuis n'importe quel format
      let videoId: string | null = null;
      
      // Pattern 1: youtube.com/watch?v=VIDEO_ID (format normal)
      // Regex simplifiée et plus robuste pour extraire l'ID depuis watch?v=VIDEO_ID
      const watchMatch = cleanUrl.match(/youtube\.com\/watch\?v=([a-zA-Z0-9_-]{11})/);
      if (watchMatch && watchMatch[1]) {
        videoId = watchMatch[1];
      }
      
      // Pattern 1b: m.youtube.com/watch?v=VIDEO_ID (format mobile)
      if (!videoId) {
        const mobileWatchMatch = cleanUrl.match(/m\.youtube\.com\/watch\?v=([a-zA-Z0-9_-]{11})/);
        if (mobileWatchMatch && mobileWatchMatch[1]) {
          videoId = mobileWatchMatch[1];
        }
      }
      
      // Pattern 1c: youtube.com/watch?v=VIDEO_ID&other=params (avec paramètres supplémentaires)
      if (!videoId) {
        const watchWithParamsMatch = cleanUrl.match(/youtube\.com\/watch\?.*[&?]v=([a-zA-Z0-9_-]{11})/);
        if (watchWithParamsMatch && watchWithParamsMatch[1]) {
          videoId = watchWithParamsMatch[1];
        }
      }
      
      // Pattern 2: youtu.be/VIDEO_ID (format court)
      if (!videoId) {
        const shortMatch = cleanUrl.match(/(?:youtu\.be\/|youtube\.com\/shorts\/)([a-zA-Z0-9_-]{11})/);
        if (shortMatch && shortMatch[1]) {
          videoId = shortMatch[1];
        }
      }
      
      // Pattern 3: youtube.com/embed/VIDEO_ID ou youtube-nocookie.com/embed/VIDEO_ID
      // Extraire l'ID et convertir en format watch
      if (!videoId) {
        const embedMatch = cleanUrl.match(/(?:youtube\.com|youtube-nocookie\.com)\/embed\/([a-zA-Z0-9_-]{11})/);
        if (embedMatch && embedMatch[1]) {
          videoId = embedMatch[1];
        }
      }
      
      // Pattern 4: youtube.com/v/VIDEO_ID (ancien format)
      if (!videoId) {
        const vMatch = cleanUrl.match(/youtube\.com\/v\/([a-zA-Z0-9_-]{11})/);
        if (vMatch && vMatch[1]) {
          videoId = vMatch[1];
        }
      }
      
      // Pattern 5: ID seul (si l'URL ne contient que l'ID de 11 caractères)
      if (!videoId) {
        const idOnlyMatch = cleanUrl.match(/^([a-zA-Z0-9_-]{11})$/);
        if (idOnlyMatch && idOnlyMatch[1]) {
          videoId = idOnlyMatch[1];
        }
      }
      
      // Si on a trouvé un ID valide, construire l'URL d'embed avec youtube.com (PAS nocookie)
      if (videoId && videoId.length === 11 && /^[a-zA-Z0-9_-]+$/.test(videoId)) {
        // Utiliser youtube.com/embed/ (PAS youtube-nocookie.com)
        return `https://www.youtube.com/embed/${videoId}`;
      }
      
      // Si on ne peut pas extraire l'ID, retourner une chaîne vide
      console.warn('Could not extract valid YouTube video ID from URL:', cleanUrl);
      return '';
    } catch (error) {
      console.error('Error in getYouTubeEmbedUrl:', error);
      return '';
    }
  }

  navigateToQuiz(): void {
    if (this.courseId() && this.lessonId() && this.quiz()) {
      // Naviguer vers le quiz de la leçon
      this.router.navigate(['/student/course', this.courseId(), 'lesson', this.lessonId(), 'quiz']);
    }
  }

  loadReviews(courseId: number): void {
    this.courseService.getCourseReviews(courseId).subscribe({
      next: (reviews) => {
        console.log('Reviews loaded:', reviews);
        this.reviews.set(reviews);
      },
      error: (error: any) => {
        console.error('Error loading reviews', error);
        // Ne pas bloquer l'affichage si les avis ne peuvent pas être chargés
      }
    });
  }

  toggleReviewForm(): void {
    if (!this.isEnrolled()) {
      alert('Vous devez être inscrit au cours pour laisser un avis.');
      return;
    }
    this.showReviewForm.set(!this.showReviewForm());
  }

  submitReview(): void {
    if (this.reviewForm.valid && this.courseId()) {
      const courseId = this.courseId()!;
      this.isSubmittingReview.set(true);
      const { rating, comment } = this.reviewForm.value;

      this.courseService.addCourseReview(courseId, rating, comment).subscribe({
        next: (review) => {
          console.log('Review submitted:', review);
          alert('Votre avis a été soumis avec succès ! Il sera visible après validation par le professeur.');
          this.reviewForm.reset({ rating: 5, comment: '' });
          this.showReviewForm.set(false);
          this.isSubmittingReview.set(false);
          // Recharger les avis
          this.loadReviews(courseId);
        },
        error: (error: any) => {
          console.error('Error submitting review', error);
          if (error.status === 400) {
            alert('Vous avez déjà laissé un avis pour ce cours.');
          } else {
            alert('Erreur lors de la soumission de l\'avis. Veuillez réessayer.');
          }
          this.isSubmittingReview.set(false);
        }
      });
    } else {
      this.markFormGroupTouched(this.reviewForm);
    }
  }

  markFormGroupTouched(formGroup: FormGroup): void {
    Object.keys(formGroup.controls).forEach(key => {
      const control = formGroup.get(key);
      control?.markAsTouched();
    });
  }

  getStars(rating: number): string {
    return '⭐'.repeat(rating);
  }
}
