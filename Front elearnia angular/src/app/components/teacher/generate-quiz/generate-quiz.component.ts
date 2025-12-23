import { Component, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, FormGroup, Validators, ReactiveFormsModule } from '@angular/forms';
import { Router, RouterModule, ActivatedRoute } from '@angular/router';
import { QuizService } from '../../../services/quiz.service';
import { CourseService } from '../../../services/course.service';
import { Quiz } from '../../../models/quiz.model';

@Component({
  selector: 'app-generate-quiz',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, RouterModule],
  templateUrl: './generate-quiz.component.html',
  styleUrl: './generate-quiz.component.css'
})
export class GenerateQuizComponent implements OnInit {
  form: FormGroup;
  generatedQuiz = signal<Quiz | null>(null);
  isGenerating = signal(false);
  isSaving = signal(false);
  lessonId: number | null = null;
  courseId: number | null = null;

  constructor(
    private fb: FormBuilder,
    private quizService: QuizService,
    private courseService: CourseService,
    private router: Router,
    private route: ActivatedRoute
  ) {
    this.form = this.fb.group({
      topic: ['', [Validators.required, Validators.minLength(3)]],
      difficulty: ['BEGINNER']
    });
  }

  ngOnInit(): void {
    // Lire les queryParams pour savoir si on doit associer le quiz à une leçon
    this.route.queryParams.subscribe(params => {
      this.lessonId = params['lessonId'] ? Number(params['lessonId']) : null;
      this.courseId = params['courseId'] ? Number(params['courseId']) : null;
    });
  }

  generateQuiz(): void {
    if (this.form.valid) {
      this.isGenerating.set(true);
      const { topic, difficulty } = this.form.value;
      this.quizService.generateQuizWithAI(topic, difficulty).subscribe({
        next: (quiz) => {
          this.generatedQuiz.set(quiz);
          this.isGenerating.set(false);
        },
        error: (error: any) => {
          console.error('Error generating quiz', error);
          this.isGenerating.set(false);
        }
      });
    }
  }

  saveQuiz(): void {
    const quiz = this.generatedQuiz();
    if (!quiz) return;

    this.isSaving.set(true);
    this.quizService.createStandaloneQuiz({
      title: quiz.title,
      description: quiz.description,
      level: quiz.level,
      passingScore: quiz.passingScore,
      maxAttempts: quiz.maxAttempts,
      questions: quiz.questions
    }).subscribe({
      next: (createdQuiz) => {
        // Si on a un lessonId et courseId, associer le quiz à la leçon
        if (this.lessonId && this.courseId && createdQuiz.id) {
          this.courseService.assignQuizToLesson(this.courseId, this.lessonId, createdQuiz.id).subscribe({
            next: () => {
              alert('Quiz créé et associé à la leçon avec succès !');
              // Rediriger vers la page d'édition du cours
              this.router.navigate(['/teacher/course', this.courseId, 'edit']);
            },
            error: (error) => {
              console.error('Error assigning quiz to lesson', error);
              alert('Quiz créé mais erreur lors de l\'association à la leçon');
              this.isSaving.set(false);
            }
          });
        } else {
          // Pas d'association nécessaire, rediriger vers la page d'accueil
          alert('Quiz créé avec succès !');
          this.router.navigate(['/teacher/home']);
        }
      },
      error: (error: any) => {
        console.error('Error saving quiz', error);
        alert('Erreur lors de la création du quiz');
        this.isSaving.set(false);
      }
    });
  }

  navigateToHome(): void {
    this.router.navigate(['/teacher/home']);
  }
}


