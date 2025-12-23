import { Component, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router, RouterModule } from '@angular/router';
import { CourseService } from '../../../services/course.service';
import { TeacherCourse } from '../../../models/course.model';
import { AuthService } from '../../../services/auth.service';
import { HealthService } from '../../../services/health.service';

@Component({
  selector: 'app-teacher-courses',
  standalone: true,
  imports: [CommonModule, RouterModule],
  templateUrl: './courses.component.html',
  styleUrl: './courses.component.css'
})
export class TeacherCoursesComponent implements OnInit {
  courses = signal<TeacherCourse[]>([]);
  isLoading = signal(false);

  constructor(
    private courseService: CourseService,
    private router: Router,
    private authService: AuthService,
    private healthService: HealthService
  ) {}

  ngOnInit(): void {
    // Vérifier que l'utilisateur est authentifié
    const user = this.authService.getCurrentUser();
    if (!user) {
      console.error('User not authenticated');
      this.router.navigate(['/login']);
      return;
    }
    console.log('Current user:', user);
    
    // Vérifier d'abord si le backend est accessible
    this.healthService.checkBackendHealth().subscribe({
      next: (isBackendAvailable) => {
        if (!isBackendAvailable) {
          alert('⚠️ Le backend n\'est pas accessible sur http://localhost:8080\n\n' +
                'Veuillez démarrer le backend Spring Boot avant de continuer.');
          this.isLoading.set(false);
          return;
        }
        this.loadCourses();
      },
      error: () => {
        alert('⚠️ Impossible de vérifier la connexion au backend.\n\n' +
              'Assurez-vous que le backend est démarré sur http://localhost:8080');
        this.isLoading.set(false);
      }
    });
  }

  loadCourses(): void {
    this.isLoading.set(true);
    
    // Vérifier le token
    const token = this.authService.getToken();
    const user = this.authService.getCurrentUser();
    
    console.log('=== LOADING COURSES ===');
    console.log('Token present:', !!token);
    console.log('User:', user);
    console.log('User role:', user?.role);
    
    if (!token) {
      console.error('No token found, redirecting to login');
      this.authService.logout();
      this.router.navigate(['/login']);
      return;
    }
    
    this.courseService.getTeacherCourses().subscribe({
      next: (courses) => {
        console.log('✅ Courses loaded successfully:', courses);
        console.log('Number of courses:', courses?.length || 0);
        this.courses.set(courses || []);
        this.isLoading.set(false);
      },
      error: (error: any) => {
        console.error('❌ === ERROR LOADING COURSES ===');
        console.error('Error object:', error);
        console.error('Error status:', error.status);
        console.error('Error statusText:', error.statusText);
        console.error('Error message:', error.message);
        console.error('Error error:', error.error);
        console.error('Error url:', error.url);
        
        let errorMessage = 'Erreur lors du chargement des cours.';
        
        if (error.status === 401 || error.status === 403) {
          errorMessage = 'Session expirée ou accès refusé. Veuillez vous reconnecter.';
          this.authService.logout();
          setTimeout(() => {
            this.router.navigate(['/login']);
          }, 1000);
        } else if (error.status === 0 || error.status === undefined || error.message?.includes('Failed to fetch')) {
          errorMessage = '❌ Impossible de se connecter au serveur.\n\n' +
                        'Vérifiez que :\n' +
                        '1. Le backend est démarré sur http://localhost:8080\n' +
                        '2. Le backend est accessible\n' +
                        '3. Aucun firewall ne bloque la connexion';
        } else if (error.status === 404) {
          errorMessage = 'Endpoint non trouvé. Vérifiez que le backend est à jour.';
        } else if (error.status >= 500) {
          errorMessage = 'Erreur serveur. Vérifiez les logs du backend.';
        } else if (error.error?.message) {
          errorMessage = error.error.message;
        }
        
        this.courses.set([]);
        this.isLoading.set(false);
        
        // Ne pas afficher l'alerte si c'est une redirection vers login
        if (error.status !== 401 && error.status !== 403) {
          alert(errorMessage);
        }
      }
    });
  }

  navigateToCreate(): void {
    this.router.navigate(['/teacher/course/create']);
  }

  navigateToEdit(courseId: number): void {
    this.router.navigate(['/teacher/course', courseId, 'edit']);
  }

  deleteCourse(courseId: number): void {
    if (confirm('Êtes-vous sûr de vouloir supprimer ce cours ?')) {
      this.courseService.deleteCourse(courseId).subscribe({
        next: () => {
          this.loadCourses();
        },
        error: (error: any) => {
          console.error('Error deleting course', error);
          alert('Erreur lors de la suppression du cours');
        }
      });
    }
  }

  navigateToHome(): void {
    this.router.navigate(['/teacher/home']);
  }
}


