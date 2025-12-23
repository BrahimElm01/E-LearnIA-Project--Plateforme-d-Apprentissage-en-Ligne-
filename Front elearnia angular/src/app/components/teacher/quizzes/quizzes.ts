import { Component, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router, RouterModule } from '@angular/router';
import { QuizService } from '../../../services/quiz.service';
import { Quiz } from '../../../models/quiz.model';

@Component({
  selector: 'app-quizzes',
  standalone: true,
  imports: [CommonModule, RouterModule],
  templateUrl: './quizzes.html',
  styleUrl: './quizzes.css'
})
export class TeacherQuizzesComponent implements OnInit {
  quizzes = signal<Quiz[]>([]);
  filteredQuizzes = signal<Quiz[]>([]);
  isLoading = signal(false);
  errorMessage = signal<string | null>(null);
  searchQuery = signal<string>('');
  filterType = signal<'all' | 'standalone' | 'course'>('all');

  constructor(
    private quizService: QuizService,
    private router: Router
  ) {}

  ngOnInit(): void {
    this.loadQuizzes();
  }

  loadQuizzes(): void {
    this.isLoading.set(true);
    this.errorMessage.set(null);
    
    this.quizService.getTeacherQuizzes().subscribe({
      next: (quizzes) => {
        console.log('Quizzes loaded:', quizzes);
        this.quizzes.set(quizzes);
        this.applyFilters();
        this.isLoading.set(false);
      },
      error: (error: any) => {
        console.error('Error loading quizzes', error);
        if (error.status === 404) {
          // Endpoint n'existe peut-être pas encore, utiliser getAllQuizzesScores comme fallback
          this.loadQuizzesFallback();
        } else {
          this.errorMessage.set('Erreur lors du chargement des quizzes');
          this.isLoading.set(false);
        }
      }
    });
  }

  loadQuizzesFallback(): void {
    // Fallback: utiliser getAllQuizzesScores pour récupérer les quizzes
    this.quizService.getAllQuizzesScores().subscribe({
      next: (scoresData: any) => {
        const quizMap = new Map<number, Quiz>();
        
        scoresData.forEach((scoreData: any) => {
          if (!quizMap.has(scoreData.quizId)) {
            const quiz: Quiz = {
              id: scoreData.quizId,
              title: scoreData.title,
              description: '',
              passingScore: 75,
              maxAttempts: 3,
              remainingAttempts: 0,
              level: scoreData.level,
              // Si courseTitle n'est pas 'Quiz standalone', c'est un quiz lié à un cours
              // Mais on n'a pas le courseId dans cette réponse, donc on laisse undefined
              // Le vrai endpoint getTeacherQuizzes devrait maintenant retourner le courseId
              courseId: scoreData.courseId || (scoreData.courseTitle !== 'Quiz standalone' ? undefined : undefined),
              questions: []
            };
            quizMap.set(scoreData.quizId, quiz);
          }
        });

        this.quizzes.set(Array.from(quizMap.values()));
        this.applyFilters();
        this.isLoading.set(false);
      },
      error: (error: any) => {
        console.error('Error loading quizzes fallback', error);
        this.errorMessage.set('Erreur lors du chargement des quizzes');
        this.isLoading.set(false);
      }
    });
  }

  applyFilters(): void {
    let filtered = [...this.quizzes()];

    // Filtre par type
    if (this.filterType() === 'standalone') {
      filtered = filtered.filter(q => !q.courseId);
    } else if (this.filterType() === 'course') {
      filtered = filtered.filter(q => q.courseId);
    }

    // Filtre par recherche
    if (this.searchQuery().trim()) {
      const query = this.searchQuery().toLowerCase();
      filtered = filtered.filter(q => 
        q.title.toLowerCase().includes(query) ||
        q.description?.toLowerCase().includes(query)
      );
    }

    this.filteredQuizzes.set(filtered);
  }

  onFilterChange(filter: 'all' | 'standalone' | 'course'): void {
    this.filterType.set(filter);
    this.applyFilters();
  }

  onSearchChange(): void {
    this.applyFilters();
  }

  navigateToHome(): void {
    this.router.navigate(['/teacher/home']);
  }

  navigateToGenerateQuiz(): void {
    this.router.navigate(['/teacher/generate-quiz']);
  }

  getLevelColor(level?: string): string {
    switch (level?.toUpperCase()) {
      case 'BEGINNER':
      case 'DÉBUTANT':
        return '#10b981'; // green
      case 'INTERMEDIATE':
      case 'INTERMÉDIAIRE':
        return '#f59e0b'; // yellow
      case 'ADVANCED':
      case 'AVANCÉ':
        return '#ef4444'; // red
      default:
        return '#667eea'; // purple
    }
  }

  getLevelLabel(level?: string): string {
    switch (level?.toUpperCase()) {
      case 'BEGINNER':
        return 'Débutant';
      case 'INTERMEDIATE':
        return 'Intermédiaire';
      case 'ADVANCED':
        return 'Avancé';
      default:
        return level || 'N/A';
    }
  }

  getTotalQuizzes(): number {
    return this.quizzes().length;
  }

  getStandaloneQuizzes(): number {
    return this.quizzes().filter(q => !q.courseId).length;
  }

  getCourseQuizzes(): number {
    return this.quizzes().filter(q => q.courseId).length;
  }

  editQuiz(quizId: number): void {
    const quiz = this.quizzes().find(q => q.id === quizId);
    if (quiz) {
      if (quiz.courseId) {
        // Quiz lié à un cours - utiliser la route avec courseId
        this.router.navigate(['/teacher/course', quiz.courseId, 'quiz', 'edit']);
      } else {
        // Quiz standalone
        this.router.navigate(['/teacher/quiz', quizId, 'edit']);
      }
    }
  }

  deleteQuiz(quizId: number): void {
    const quiz = this.quizzes().find(q => q.id === quizId);
    if (!quiz) return;

    const confirmed = confirm('Êtes-vous sûr de vouloir supprimer ce quiz ? Cette action est irréversible.');
    if (!confirmed) return;

    const deleteObservable = quiz.courseId
      ? this.quizService.deleteCourseQuiz(quiz.courseId)
      : this.quizService.deleteStandaloneQuiz(quizId);

    deleteObservable.subscribe({
      next: () => {
        alert('Quiz supprimé avec succès');
        this.loadQuizzes();
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
