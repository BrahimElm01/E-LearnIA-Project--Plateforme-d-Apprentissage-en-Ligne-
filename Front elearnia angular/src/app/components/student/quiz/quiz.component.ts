import { Component, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ActivatedRoute, Router, RouterModule } from '@angular/router';
import { QuizService } from '../../../services/quiz.service';
import { Quiz, Question, QuizResult } from '../../../models/quiz.model';

@Component({
  selector: 'app-quiz',
  standalone: true,
  imports: [CommonModule, RouterModule],
  templateUrl: './quiz.component.html',
  styleUrl: './quiz.component.css'
})
export class QuizComponent implements OnInit {
  quiz = signal<Quiz | null>(null);
  answers = signal<Map<number, string>>(new Map());
  isLoading = signal(false);
  isSubmitting = signal(false);
  errorMessage = signal<string | null>(null);
  quizResult = signal<QuizResult | null>(null);
  showResult = signal(false);
  courseId = signal<number | null>(null);
  isCourseQuiz = signal<boolean>(false);

  constructor(
    private route: ActivatedRoute,
    private router: Router,
    private quizService: QuizService
  ) {}

  ngOnInit(): void {
    // Vérifier si c'est un quiz lié à une leçon (route: /student/course/:courseId/lesson/:lessonId/quiz)
    const courseIdParam = this.route.snapshot.paramMap.get('courseId');
    const lessonIdParam = this.route.snapshot.paramMap.get('lessonId');
    const quizIdParam = this.route.snapshot.paramMap.get('id');
    
    if (courseIdParam && lessonIdParam) {
      // Quiz lié à une leçon
      const courseId = Number(courseIdParam);
      const lessonId = Number(lessonIdParam);
      if (!isNaN(courseId) && !isNaN(lessonId)) {
        this.courseId.set(courseId);
        this.isCourseQuiz.set(true);
        this.loadLessonQuiz(courseId, lessonId);
        return;
      }
    }
    
    if (courseIdParam && !lessonIdParam) {
      // Quiz lié à un cours (ancien format)
      const courseId = Number(courseIdParam);
      if (!isNaN(courseId)) {
        this.courseId.set(courseId);
        this.isCourseQuiz.set(true);
        this.loadCourseQuiz(courseId);
        return;
      }
    }
    
    // Quiz standalone
    if (quizIdParam) {
      const quizId = Number(quizIdParam);
      if (!isNaN(quizId)) {
        this.loadQuiz(quizId);
        return;
      }
    }
    
    this.router.navigate(['/student/quizzes']);
  }

  loadQuiz(quizId: number): void {
    this.isLoading.set(true);
    this.errorMessage.set(null);
    this.quizService.getStandaloneQuiz(quizId).subscribe({
      next: (quiz) => {
        this.quiz.set(quiz);
        this.isLoading.set(false);
      },
      error: (error: any) => {
        console.error('Error loading quiz', error);
        this.errorMessage.set('Erreur lors du chargement du quiz. Veuillez réessayer.');
        this.isLoading.set(false);
        setTimeout(() => {
          this.router.navigate(['/student/quizzes']);
        }, 3000);
      }
    });
  }

  loadCourseQuiz(courseId: number): void {
    this.isLoading.set(true);
    this.errorMessage.set(null);
    this.quizService.getQuizByCourse(courseId).subscribe({
      next: (quiz) => {
        console.log('Course quiz loaded:', quiz);
        this.quiz.set(quiz);
        this.isLoading.set(false);
      },
      error: (error: any) => {
        console.error('Error loading course quiz', error);
        if (error.status === 404) {
          this.errorMessage.set('Aucun quiz disponible pour ce cours.');
        } else {
          this.errorMessage.set('Erreur lors du chargement du quiz.');
        }
        this.isLoading.set(false);
      }
    });
  }

  loadLessonQuiz(courseId: number, lessonId: number): void {
    this.isLoading.set(true);
    this.errorMessage.set(null);
    this.quizService.getLessonQuiz(courseId, lessonId).subscribe({
      next: (quiz) => {
        console.log('Lesson quiz loaded:', quiz);
        this.quiz.set(quiz);
        this.isLoading.set(false);
      },
      error: (error: any) => {
        console.error('Error loading lesson quiz', error);
        if (error.status === 404) {
          this.errorMessage.set('Aucun quiz disponible pour cette leçon.');
        } else {
          this.errorMessage.set('Erreur lors du chargement du quiz.');
        }
        this.isLoading.set(false);
      }
    });
  }

  selectAnswer(questionId: number, answer: string): void {
    const currentAnswers = new Map(this.answers());
    currentAnswers.set(questionId, answer);
    this.answers.set(currentAnswers);
    this.errorMessage.set(null);
  }

  submitQuiz(): void {
    const quiz = this.quiz();
    if (!quiz) {
      this.errorMessage.set('Erreur : Quiz introuvable');
      return;
    }

    // Vérifier qu'au moins une question a été répondue
    if (this.answers().size === 0) {
      this.errorMessage.set('Veuillez répondre à au moins une question avant de soumettre.');
      return;
    }

    // Avertir si toutes les questions ne sont pas répondues
    const unansweredCount = quiz.questions.length - this.answers().size;
    if (unansweredCount > 0) {
      const confirmed = confirm(
        `Vous n'avez pas répondu à ${unansweredCount} question(s). Voulez-vous quand même soumettre le quiz ?`
      );
      if (!confirmed) {
        return;
      }
    }

    this.isSubmitting.set(true);
    this.errorMessage.set(null);

    console.log('Submitting quiz:', quiz.id);
    console.log('Answers:', Array.from(this.answers().entries()));

    // Déterminer quel service utiliser pour soumettre le quiz
    let submitObservable;
    const lessonIdParam = this.route.snapshot.paramMap.get('lessonId');
    
    if (lessonIdParam && this.courseId()) {
      // Quiz de leçon - utiliser submitQuiz avec courseId
      submitObservable = this.quizService.submitQuiz(this.courseId()!, this.answers());
    } else if (this.isCourseQuiz() && this.courseId()) {
      // Quiz de cours (ancien format)
      submitObservable = this.quizService.submitQuiz(this.courseId()!, this.answers());
    } else {
      // Quiz standalone
      submitObservable = this.quizService.submitStandaloneQuiz(quiz.id, this.answers());
    }

    submitObservable.subscribe({
      next: (result) => {
        console.log('Quiz submitted successfully:', result);
        this.quizResult.set(result);
        this.showResult.set(true);
        this.isSubmitting.set(false);
      },
      error: (error: any) => {
        console.error('Error submitting quiz', error);
        console.error('Error details:', {
          status: error.status,
          message: error.message,
          error: error.error
        });
        
        let errorMsg = 'Erreur lors de la soumission du quiz.';
        
        if (error.status === 400) {
          errorMsg = error.error?.message || 'Requête invalide. Vérifiez vos réponses.';
        } else if (error.status === 403) {
          errorMsg = 'Vous avez atteint le nombre maximum de tentatives pour ce quiz.';
        } else if (error.status === 404) {
          errorMsg = 'Quiz introuvable.';
        } else if (error.status === 0) {
          errorMsg = 'Impossible de se connecter au serveur. Vérifiez votre connexion.';
        }
        
        this.errorMessage.set(errorMsg);
        this.isSubmitting.set(false);
      }
    });
  }

  isAnswerSelected(questionId: number, answer: string): boolean {
    return this.answers().get(questionId) === answer;
  }

  getAnsweredCount(): number {
    return this.answers().size;
  }

  getTotalQuestions(): number {
    return this.quiz()?.questions.length || 0;
  }

  goBackToQuizzes(): void {
    const lessonIdParam = this.route.snapshot.paramMap.get('lessonId');
    
    if (lessonIdParam && this.courseId()) {
      // Retourner à la leçon
      this.router.navigate(['/student/course', this.courseId(), 'lesson', lessonIdParam]);
    } else if (this.isCourseQuiz() && this.courseId()) {
      // Retourner au cours
      this.router.navigate(['/student/course', this.courseId()]);
    } else {
      // Retourner à la liste des quizzes
      this.router.navigate(['/student/quizzes']);
    }
  }

  navigateToQuizzes(): void {
    this.goBackToQuizzes();
  }

  retakeQuiz(): void {
    this.showResult.set(false);
    this.quizResult.set(null);
    this.answers.set(new Map());
    this.errorMessage.set(null);
  }

  getCorrectAnswersCount(): number {
    const result = this.quizResult();
    if (!result || result.score < 0) return 0;
    return Math.round((result.score / 100) * this.getTotalQuestions());
  }
}



