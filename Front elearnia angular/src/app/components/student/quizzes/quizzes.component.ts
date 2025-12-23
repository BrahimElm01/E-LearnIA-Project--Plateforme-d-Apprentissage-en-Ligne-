import { Component, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router, RouterModule } from '@angular/router';
import { QuizService } from '../../../services/quiz.service';
import { QuizSummary } from '../../../models/quiz.model';

@Component({
  selector: 'app-quizzes',
  standalone: true,
  imports: [CommonModule, RouterModule, FormsModule],
  templateUrl: './quizzes.component.html',
  styleUrl: './quizzes.component.css'
})
export class QuizzesComponent implements OnInit {
  quizzes = signal<QuizSummary[]>([]);
  filteredQuizzes = signal<QuizSummary[]>([]);
  isLoading = signal(false);
  selectedLevel = signal<string>('ALL');
  searchQuery = signal<string>('');

  constructor(
    private quizService: QuizService,
    private router: Router
  ) {}

  ngOnInit(): void {
    this.loadQuizzes();
  }

  loadQuizzes(): void {
    this.isLoading.set(true);
    // Ne pas envoyer 'ALL' comme valeur, envoyer undefined à la place
    const level = this.selectedLevel() === 'ALL' ? undefined : this.selectedLevel();
    
    this.quizService.getAvailableQuizzes(level).subscribe({
      next: (quizzes) => {
        console.log('Quizzes loaded:', quizzes);
        this.quizzes.set(quizzes || []);
        this.applyFilters();
        this.isLoading.set(false);
      },
      error: (error: any) => {
        console.error('Error loading quizzes', error);
        console.error('Error details:', {
          status: error.status,
          message: error.message,
          error: error.error
        });
        
        // Si l'erreur est 401 (non authentifié), rediriger vers la page de connexion
        if (error.status === 401 || error.status === 403) {
          console.warn('Authentication required. Redirecting to login...');
          // Ne pas rediriger automatiquement, juste afficher une liste vide
        }
        
        // En cas d'erreur, initialiser avec une liste vide
        this.quizzes.set([]);
        this.filteredQuizzes.set([]);
        this.isLoading.set(false);
      }
    });
  }

  applyFilters(): void {
    let filtered = [...this.quizzes()];

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

  onLevelChange(level: string): void {
    this.selectedLevel.set(level);
    this.loadQuizzes();
  }

  onSearchChange(): void {
    this.applyFilters();
  }

  navigateToQuiz(quizId: number): void {
    this.router.navigate(['/student/quiz', quizId]);
  }

  getLevelColor(level: string): string {
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

  getLevelLabel(level: string): string {
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

  canTakeQuiz(remainingAttempts: number): boolean {
    return remainingAttempts > 0;
  }

  navigateBack(): void {
    this.router.navigate(['/student/home']);
  }
}



