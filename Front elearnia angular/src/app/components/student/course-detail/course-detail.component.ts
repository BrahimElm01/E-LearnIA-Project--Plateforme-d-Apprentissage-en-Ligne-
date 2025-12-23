import { Component, OnInit, signal } from '@angular/core';
import { CommonModule, DatePipe } from '@angular/common';
import { FormBuilder, FormGroup, Validators, ReactiveFormsModule } from '@angular/forms';
import { ActivatedRoute, Router, RouterModule } from '@angular/router';
import { CourseService } from '../../../services/course.service';
import { Course } from '../../../models/course.model';
import { Lesson } from '../../../models/lesson.model';

@Component({
  selector: 'app-course-detail',
  standalone: true,
  imports: [CommonModule, RouterModule, ReactiveFormsModule, DatePipe],
  templateUrl: './course-detail.component.html',
  styleUrl: './course-detail.component.css'
})
export class CourseDetailComponent implements OnInit {
  course = signal<Course | null>(null);
  lessons = signal<Lesson[]>([]);
  isLoading = signal(false);
  errorMessage = signal<string | null>(null);
  isEnrolled = signal<boolean>(false);
  isEnrolling = signal<boolean>(false);
  enrollmentMessage = signal<string | null>(null);
  reviews = signal<any[]>([]);
  reviewForm!: FormGroup;
  isSubmittingReview = signal<boolean>(false);
  showReviewForm = signal<boolean>(false);
  completedLessons = signal<Set<number>>(new Set());
  lessonQuizzes = signal<Map<number, any>>(new Map());
  isMarkingComplete = signal<Map<number, boolean>>(new Map());

  constructor(
    private route: ActivatedRoute,
    private router: Router,
    private courseService: CourseService,
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
    const courseIdParam = this.route.snapshot.paramMap.get('id');
    if (!courseIdParam) {
      this.errorMessage.set('ID de cours invalide');
      return;
    }
    const courseId = Number(courseIdParam);
    if (isNaN(courseId) || courseId <= 0) {
      this.errorMessage.set('ID de cours invalide');
      return;
    }
    // Charger le cours d'abord, puis s'inscrire automatiquement, puis charger les leçons
    this.loadCourseAndEnroll(courseId);
  }

  loadCourseAndEnroll(courseId: number): void {
    this.isLoading.set(true);
    this.errorMessage.set(null);
    this.isEnrolling.set(true);
    
    // Étape 1: S'inscrire d'abord au cours (le backend gère le cas où on est déjà inscrit)
    this.courseService.enrollToCourse(courseId).subscribe({
      next: () => {
        console.log('Successfully enrolled (or already enrolled)');
        this.isEnrolled.set(true);
        this.isEnrolling.set(false);
        
        // Étape 2: Maintenant charger les détails du cours
        this.loadCourseDetails(courseId);
      },
      error: (error: any) => {
        console.error('Error enrolling', error);
        this.isEnrolling.set(false);
        
        // Même en cas d'erreur, essayer de charger le cours (peut-être déjà inscrit)
        if (error.status === 400) {
          // Probablement déjà inscrit, continuer quand même
          console.log('Already enrolled (400 response), continuing...');
          this.isEnrolled.set(true);
          this.loadCourseDetails(courseId);
        } else if (error.status === 404) {
          this.errorMessage.set('Cours introuvable');
          this.isLoading.set(false);
        } else {
          // Essayer quand même de charger le cours
          this.loadCourseDetails(courseId);
        }
      }
    });
  }

  loadCourseDetails(courseId: number): void {
    this.courseService.getCourseDetails(courseId).subscribe({
      next: (course) => {
        console.log('Course loaded:', course);
        this.course.set(course);
        
        // Étape 3: Charger les leçons (qui chargera aussi les leçons complétées) et les avis
        this.loadLessons(courseId);
        this.loadReviews(courseId);
        this.isLoading.set(false);
      },
      error: (error: any) => {
        console.error('Error loading course', error);
        if (error.status === 404) {
          this.errorMessage.set('Cours introuvable');
        } else if (error.status === 403 || error.status === 400) {
          // Si erreur 403/400, peut-être que l'inscription n'a pas fonctionné
          // Réessayer l'inscription puis recharger
          this.errorMessage.set('Erreur d\'accès au cours. Réessai de l\'inscription...');
          setTimeout(() => {
            this.retryEnrollmentAndLoad(courseId);
          }, 1000);
        } else {
          this.errorMessage.set('Erreur lors du chargement du cours');
          this.isLoading.set(false);
        }
      }
    });
  }

  retryEnrollmentAndLoad(courseId: number): void {
    this.courseService.enrollToCourse(courseId).subscribe({
      next: () => {
        this.isEnrolled.set(true);
        this.loadCourseDetails(courseId);
      },
      error: (error: any) => {
        console.error('Retry enrollment failed', error);
        this.errorMessage.set('Impossible d\'accéder à ce cours. Veuillez contacter le support.');
        this.isLoading.set(false);
      }
    });
  }


  loadLessons(courseId: number): void {
    this.courseService.getCourseLessons(courseId).subscribe({
      next: (lessons) => {
        console.log('Lessons loaded:', lessons);
        this.lessons.set(lessons);
        // Charger les quizzes et l'état de complétion pour chaque leçon
        lessons.forEach(lesson => {
          this.loadLessonQuiz(courseId, lesson.id);
        });
        // Charger les leçons complétées après avoir chargé les leçons
        this.loadCompletedLessons(courseId);
      },
      error: (error: any) => {
        console.error('Error loading lessons', error);
        if (error.status === 400) {
          // L'étudiant n'est probablement pas encore inscrit
          console.log('Lessons not available yet, enrollment may be pending');
          this.lessons.set([]);
        } else {
          this.lessons.set([]);
        }
      }
    });
  }

  loadLessonQuiz(courseId: number, lessonId: number): void {
    this.courseService.getLessonQuiz(courseId, lessonId).subscribe({
      next: (quiz) => {
        if (quiz && quiz.id) {
          const currentQuizzes = new Map(this.lessonQuizzes());
          currentQuizzes.set(lessonId, quiz);
          this.lessonQuizzes.set(currentQuizzes);
        }
      },
      error: (error: any) => {
        // Pas de quiz pour cette leçon, c'est normal
        if (error.status !== 404) {
          console.warn('Error loading quiz for lesson', lessonId, error);
        }
      }
    });
  }

  markLessonAsComplete(lessonId: number, event: Event): void {
    event.stopPropagation(); // Empêcher la navigation vers la leçon
    
    const courseId = Number(this.route.snapshot.paramMap.get('id'));
    if (isNaN(courseId)) return;

    // Vérifier si déjà complétée
    if (this.completedLessons().has(lessonId)) {
      return;
    }

    // Mettre à jour l'état de chargement
    const currentMarking = new Map(this.isMarkingComplete());
    currentMarking.set(lessonId, true);
    this.isMarkingComplete.set(currentMarking);

    // Calculer la nouvelle progression
    const totalLessons = this.lessons().length;
    const currentCompleted = this.completedLessons().size;
    const newCompleted = currentCompleted + 1;
    const newProgress = totalLessons > 0 ? Math.min(100, (newCompleted / totalLessons) * 100) : 0;
    const isCourseCompleted = newProgress >= 100;

    // Mettre à jour la progression côté backend
    this.courseService.updateProgress(courseId, newProgress, isCourseCompleted).subscribe({
      next: (response) => {
        console.log('Lesson marked as complete:', lessonId);
        console.log('Progress updated:', newProgress, '%');
        
        // Mettre à jour localement les leçons complétées
        const completed = new Set(this.completedLessons());
        completed.add(lessonId);
        this.completedLessons.set(completed);
        
        // Retirer l'état de chargement
        currentMarking.set(lessonId, false);
        this.isMarkingComplete.set(currentMarking);
        
        // Recharger les détails du cours pour mettre à jour la progression affichée
        this.loadCourseDetails(courseId);
      },
      error: (error: any) => {
        console.error('Error marking lesson as complete', error);
        alert('Erreur lors du marquage de la leçon comme terminée');
        currentMarking.set(lessonId, false);
        this.isMarkingComplete.set(currentMarking);
      }
    });
  }

  navigateToLessonQuiz(lessonId: number, event: Event): void {
    event.stopPropagation(); // Empêcher la navigation vers la leçon
    
    const courseId = Number(this.route.snapshot.paramMap.get('id'));
    if (isNaN(courseId)) return;

    // Naviguer vers le quiz de la leçon
    this.router.navigate(['/student/course', courseId, 'lesson', lessonId, 'quiz']);
  }

  isLessonCompleted(lessonId: number): boolean {
    return this.completedLessons().has(lessonId);
  }

  hasLessonQuiz(lessonId: number): boolean {
    return this.lessonQuizzes().has(lessonId);
  }

  getLessonQuiz(lessonId: number): any {
    return this.lessonQuizzes().get(lessonId);
  }

  loadCompletedLessons(courseId: number): void {
    // Charger la progression du cours depuis la liste des cours de l'étudiant
    this.courseService.getStudentCourses().subscribe({
      next: (courses) => {
        const course = courses.find(c => c.id === courseId);
        if (course && course.progress > 0) {
          // Calculer approximativement le nombre de leçons complétées à partir de la progression
          const totalLessons = this.lessons().length;
          if (totalLessons > 0) {
            const completedCount = Math.round((course.progress / 100) * totalLessons);
            // Marquer les premières leçons comme complétées (approximation)
            // En production, il faudrait un endpoint backend pour obtenir les leçons complétées exactes
            const completed = new Set<number>();
            const sortedLessons = [...this.lessons()].sort((a, b) => a.orderIndex - b.orderIndex);
            for (let i = 0; i < completedCount && i < sortedLessons.length; i++) {
              completed.add(sortedLessons[i].id);
            }
            this.completedLessons.set(completed);
          }
        }
      },
      error: (error) => {
        console.warn('Could not load course progress, initializing with empty set', error);
        this.completedLessons.set(new Set());
      }
    });
  }

  enrollToCourse(): void {
    const courseId = Number(this.route.snapshot.paramMap.get('id'));
    if (isNaN(courseId)) {
      alert('ID de cours invalide');
      return;
    }

    this.isEnrolling.set(true);
    this.enrollmentMessage.set(null);

    this.courseService.enrollToCourse(courseId).subscribe({
      next: () => {
        console.log('Successfully enrolled in course');
        this.isEnrolled.set(true);
        this.isEnrolling.set(false);
        this.enrollmentMessage.set('Inscription réussie !');
        // Recharger les leçons après l'inscription
        this.loadLessons(courseId);
        this.loadReviews(courseId);
      },
      error: (error: any) => {
        console.error('Error enrolling', error);
        this.isEnrolling.set(false);
        if (error.status === 400) {
          this.enrollmentMessage.set('Vous êtes déjà inscrit à ce cours');
          this.isEnrolled.set(true);
          // Recharger les leçons même si déjà inscrit
          this.loadLessons(courseId);
          this.loadReviews(courseId);
        } else if (error.status === 404) {
          this.enrollmentMessage.set('Cours introuvable');
          alert('Erreur : Cours introuvable');
        } else if (error.status === 403) {
          this.enrollmentMessage.set('Vous n\'êtes pas autorisé à vous inscrire à ce cours');
          alert('Erreur : Vous n\'êtes pas autorisé à vous inscrire à ce cours');
        } else {
          this.enrollmentMessage.set('Erreur lors de l\'inscription');
          alert('Erreur lors de l\'inscription. Veuillez réessayer.');
        }
      }
    });
  }

  navigateToLesson(lessonId: number): void {
    const courseId = Number(this.route.snapshot.paramMap.get('id'));
    this.router.navigate(['/student/course', courseId, 'lesson', lessonId]);
  }

  navigateToCourseReader(): void {
    const courseId = Number(this.route.snapshot.paramMap.get('id'));
    this.router.navigate(['/student/course', courseId, 'read']);
  }

  navigateBack(): void {
    this.router.navigate(['/student/courses']);
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
    if (this.reviewForm.valid) {
      const courseId = Number(this.route.snapshot.paramMap.get('id'));
      if (isNaN(courseId)) return;

      this.isSubmittingReview.set(true);
      const { rating, comment } = this.reviewForm.value;

      this.courseService.addCourseReview(courseId, rating, comment).subscribe({
        next: (review) => {
          console.log('Review submitted:', review);
          alert('Votre avis a été soumis avec succès ! Il sera visible après validation par le professeur.');
          this.reviewForm.reset({ rating: 5, comment: '' });
          this.showReviewForm.set(false);
          this.isSubmittingReview.set(false);
          // Recharger les avis (même si le nouveau n'est pas encore approuvé)
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

  getDescriptionPreview(description: string): string {
    if (!description) return '';
    // Limiter à 150 caractères maximum
    const maxLength = 150;
    if (description.length <= maxLength) {
      return description;
    }
    // Tronquer et ajouter des points de suspension
    return description.substring(0, maxLength).trim() + '...';
  }
}

