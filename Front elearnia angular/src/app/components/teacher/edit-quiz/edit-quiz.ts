import { Component, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, FormGroup, FormArray, Validators, ReactiveFormsModule } from '@angular/forms';
import { Router, RouterModule, ActivatedRoute } from '@angular/router';
import { QuizService } from '../../../services/quiz.service';
import { Quiz, Question } from '../../../models/quiz.model';

@Component({
  selector: 'app-edit-quiz',
  standalone: true,
  imports: [CommonModule, RouterModule, ReactiveFormsModule],
  templateUrl: './edit-quiz.html',
  styleUrl: './edit-quiz.css'
})
export class EditQuizComponent implements OnInit {
  quizId = signal<number | null>(null);
  courseId = signal<number | null>(null);
  quiz = signal<Quiz | null>(null);
  quizForm!: FormGroup;
  isLoading = signal(false);
  isSaving = signal(false);
  errorMessage = signal<string | null>(null);
  isStandalone = signal<boolean>(true);

  constructor(
    private fb: FormBuilder,
    private quizService: QuizService,
    private router: Router,
    private route: ActivatedRoute
  ) {
    this.initForm();
  }

  ngOnInit(): void {
    // Vérifier si c'est un quiz lié à un cours (route: /teacher/course/:courseId/quiz/edit)
    const courseIdParam = this.route.snapshot.paramMap.get('courseId');
    const quizIdParam = this.route.snapshot.paramMap.get('id');
    
    if (courseIdParam) {
      // Quiz lié à un cours
      const courseId = Number(courseIdParam);
      if (isNaN(courseId)) {
        this.router.navigate(['/teacher/quizzes']);
        return;
      }
      this.courseId.set(courseId);
      this.isStandalone.set(false);
      this.loadCourseQuiz();
    } else if (quizIdParam) {
      // Quiz standalone
      const id = Number(quizIdParam);
      if (isNaN(id)) {
        this.router.navigate(['/teacher/quizzes']);
        return;
      }
      this.quizId.set(id);
      this.isStandalone.set(true);
      this.loadQuiz();
    } else {
      this.router.navigate(['/teacher/quizzes']);
    }
  }

  initForm(): void {
    this.quizForm = this.fb.group({
      title: ['', [Validators.required, Validators.minLength(3)]],
      description: [''],
      passingScore: [75, [Validators.required, Validators.min(0), Validators.max(100)]],
      maxAttempts: [3, [Validators.required, Validators.min(1)]],
      level: ['BEGINNER', [Validators.required]],
      questions: this.fb.array([])
    });
  }

  get questionsFormArray(): FormArray {
    return this.quizForm.get('questions') as FormArray;
  }

  loadQuiz(): void {
    if (!this.quizId()) return;
    
    this.isLoading.set(true);
    this.errorMessage.set(null);

    this.quizService.getStandaloneQuizForTeacher(this.quizId()!).subscribe({
      next: (quiz) => {
        this.quiz.set(quiz);
        this.populateForm(quiz);
        this.isLoading.set(false);
      },
      error: (error: any) => {
        console.error('Error loading quiz', error);
        this.errorMessage.set('Erreur lors du chargement du quiz');
        this.isLoading.set(false);
        setTimeout(() => {
          this.router.navigate(['/teacher/quizzes']);
        }, 2000);
      }
    });
  }

  loadCourseQuiz(): void {
    if (!this.courseId()) return;
    
    this.isLoading.set(true);
    this.errorMessage.set(null);

    this.quizService.getCourseQuiz(this.courseId()!).subscribe({
      next: (quiz) => {
        this.quiz.set(quiz);
        this.quizId.set(quiz.id);
        this.populateForm(quiz);
        this.isLoading.set(false);
      },
      error: (error: any) => {
        console.error('Error loading course quiz', error);
        if (error.status === 404) {
          this.errorMessage.set('Aucun quiz trouvé pour ce cours');
        } else {
          this.errorMessage.set('Erreur lors du chargement du quiz');
        }
        this.isLoading.set(false);
        setTimeout(() => {
          this.router.navigate(['/teacher/quizzes']);
        }, 2000);
      }
    });
  }

  populateForm(quiz: Quiz): void {
    this.quizForm.patchValue({
      title: quiz.title,
      description: quiz.description || '',
      passingScore: quiz.passingScore,
      maxAttempts: quiz.maxAttempts,
      level: quiz.level || 'BEGINNER'
    });

    // Vider le FormArray existant
    while (this.questionsFormArray.length !== 0) {
      this.questionsFormArray.removeAt(0);
    }

    // Ajouter les questions
    if (quiz.questions && quiz.questions.length > 0) {
      quiz.questions.forEach(question => {
        this.addQuestion(question);
      });
    }
  }

  addQuestion(question?: Question): void {
    const questionGroup = this.fb.group({
      text: [question?.text || '', [Validators.required, Validators.minLength(5)]],
      correctAnswer: [question?.correctAnswer || '', [Validators.required]],
      options: this.fb.array(
        question?.options && question.options.length > 0
          ? question.options.map(opt => this.fb.control(opt, Validators.required))
          : [
              this.fb.control('', Validators.required),
              this.fb.control('', Validators.required),
              this.fb.control('', Validators.required),
              this.fb.control('', Validators.required)
            ]
      ),
      points: [question?.points || 1, [Validators.required, Validators.min(1)]]
    });
    this.questionsFormArray.push(questionGroup);
  }

  addOption(questionIndex: number): void {
    const optionsArray = this.getQuestionOptions(questionIndex);
    optionsArray.push(this.fb.control('', Validators.required));
  }

  removeOption(questionIndex: number, optionIndex: number): void {
    const optionsArray = this.getQuestionOptions(questionIndex);
    if (optionsArray.length > 2) {
      const currentCorrectAnswer = this.getQuestionControl(questionIndex, 'correctAnswer')?.value;
      const optionToRemove = optionsArray.at(optionIndex).value;
      
      // Si on supprime l'option qui est la réponse correcte, réinitialiser la réponse correcte
      if (currentCorrectAnswer === optionToRemove) {
        this.getQuestionControl(questionIndex, 'correctAnswer')?.setValue('');
      }
      
      optionsArray.removeAt(optionIndex);
    } else {
      alert('Une question doit avoir au moins 2 options.');
    }
  }

  moveQuestionUp(index: number): void {
    if (index > 0) {
      const question = this.questionsFormArray.at(index);
      this.questionsFormArray.removeAt(index);
      this.questionsFormArray.insert(index - 1, question);
    }
  }

  moveQuestionDown(index: number): void {
    if (index < this.questionsFormArray.length - 1) {
      const question = this.questionsFormArray.at(index);
      this.questionsFormArray.removeAt(index);
      this.questionsFormArray.insert(index + 1, question);
    }
  }

  removeQuestion(index: number): void {
    if (this.questionsFormArray.length > 1) {
      this.questionsFormArray.removeAt(index);
    } else {
      alert('Un quiz doit avoir au moins une question.');
    }
  }

  getQuestionOptions(index: number): FormArray {
    return this.questionsFormArray.at(index).get('options') as FormArray;
  }

  getQuestionControl(index: number, controlName: string): any {
    return this.questionsFormArray.at(index).get(controlName);
  }

  getOptionControl(questionIndex: number, optionIndex: number): any {
    return this.getQuestionOptions(questionIndex).at(optionIndex);
  }

  onSubmit(): void {
    if (!this.quizForm.valid) {
      this.markFormGroupTouched(this.quizForm);
      return;
    }

    this.isSaving.set(true);
    this.errorMessage.set(null);

    const formValue = this.quizForm.value;
    const quizData = {
      title: formValue.title,
      description: formValue.description,
      passingScore: formValue.passingScore,
      maxAttempts: formValue.maxAttempts,
      level: formValue.level,
      questions: formValue.questions.map((q: any) => ({
        text: q.text,
        correctAnswer: q.correctAnswer,
        options: q.options,
        points: q.points
      }))
    };

    const updateObservable = this.isStandalone()
      ? this.quizService.updateStandaloneQuiz(this.quizId()!, quizData)
      : this.quizService.updateCourseQuiz(this.courseId()!, quizData);

    updateObservable.subscribe({
      next: (updatedQuiz) => {
        console.log('Quiz updated successfully:', updatedQuiz);
        alert('Quiz modifié avec succès !');
        this.router.navigate(['/teacher/quizzes']);
      },
      error: (error: any) => {
        console.error('Error updating quiz', error);
        if (error.status === 403) {
          this.errorMessage.set('Vous n\'êtes pas autorisé à modifier ce quiz');
        } else if (error.status === 404) {
          this.errorMessage.set('Quiz introuvable');
        } else {
          this.errorMessage.set('Erreur lors de la modification du quiz');
        }
        this.isSaving.set(false);
      }
    });
  }

  markFormGroupTouched(formGroup: FormGroup): void {
    Object.keys(formGroup.controls).forEach(key => {
      const control = formGroup.get(key);
      control?.markAsTouched();

      if (control instanceof FormGroup) {
        this.markFormGroupTouched(control);
      } else if (control instanceof FormArray) {
        control.controls.forEach(arrayControl => {
          if (arrayControl instanceof FormGroup) {
            this.markFormGroupTouched(arrayControl);
          } else {
            arrayControl.markAsTouched();
          }
        });
      }
    });
  }

  cancel(): void {
    this.router.navigate(['/teacher/quizzes']);
  }

  deleteQuiz(): void {
    const confirmed = confirm('Êtes-vous sûr de vouloir supprimer ce quiz ? Cette action est irréversible.');
    if (!confirmed) return;

    const deleteObservable = this.isStandalone()
      ? this.quizService.deleteStandaloneQuiz(this.quizId()!)
      : this.quizService.deleteCourseQuiz(this.courseId()!);

    deleteObservable.subscribe({
      next: () => {
        alert('Quiz supprimé avec succès');
        this.router.navigate(['/teacher/quizzes']);
      },
      error: (error: any) => {
        console.error('Error deleting quiz', error);
        if (error.status === 403) {
          alert('Vous n\'êtes pas autorisé à supprimer ce quiz');
        } else if (error.status === 404) {
          alert('Quiz introuvable');
        } else {
          alert('Erreur lors de la suppression du quiz');
        }
      }
    });
  }
}
