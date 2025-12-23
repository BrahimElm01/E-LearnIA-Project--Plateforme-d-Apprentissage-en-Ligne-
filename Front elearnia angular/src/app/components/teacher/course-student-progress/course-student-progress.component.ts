import { Component, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router, RouterModule, ActivatedRoute } from '@angular/router';
import { CourseService } from '../../../services/course.service';
import { StudentProgress, TeacherCourse } from '../../../models/course.model';

@Component({
  selector: 'app-course-student-progress',
  standalone: true,
  imports: [CommonModule, RouterModule],
  templateUrl: './course-student-progress.component.html',
  styleUrl: './course-student-progress.component.css'
})
export class CourseStudentProgress implements OnInit {
  courseId = signal<number | null>(null);
  course = signal<TeacherCourse | null>(null);
  students = signal<StudentProgress[]>([]);
  isLoading = signal(false);
  errorMessage = signal<string | null>(null);

  constructor(
    private courseService: CourseService,
    private router: Router,
    private route: ActivatedRoute
  ) {}

  ngOnInit(): void {
    console.log('CourseStudentProgress component initialized');
    const courseIdParam = this.route.snapshot.paramMap.get('courseId');
    console.log('CourseId from route:', courseIdParam);
    const id = Number(courseIdParam);
    if (isNaN(id) || id <= 0) {
      console.error('Invalid courseId:', courseIdParam);
      alert('ID de cours invalide');
      this.router.navigate(['/teacher/progress']);
      return;
    }
    console.log('Valid courseId:', id);
    this.courseId.set(id);
    this.loadCourse();
    this.loadStudentProgress();
  }

  loadCourse(): void {
    if (!this.courseId()) return;
    this.courseService.getTeacherCourseById(this.courseId()!).subscribe({
      next: (course) => {
        this.course.set(course);
      },
      error: (error: any) => {
        console.error('Error loading course', error);
      }
    });
  }

  loadStudentProgress(): void {
    if (!this.courseId()) {
      console.error('No courseId available');
      return;
    }
    this.isLoading.set(true);
    this.errorMessage.set(null);
    
    console.log('Loading student progress for course:', this.courseId());
    this.courseService.getStudentProgress(this.courseId()!).subscribe({
      next: (students) => {
        console.log('Student progress loaded:', students);
        this.students.set(students);
        this.isLoading.set(false);
      },
      error: (error: any) => {
        console.error('Error loading student progress', error);
        console.error('Error status:', error.status);
        console.error('Error message:', error.message);
        if (error.status === 401 || error.status === 403) {
          this.errorMessage.set('Vous n\'êtes pas autorisé à voir cette progression');
        } else if (error.status === 404) {
          this.errorMessage.set('Cours introuvable');
        } else {
          this.errorMessage.set('Erreur lors du chargement de la progression des étudiants');
        }
        this.isLoading.set(false);
      }
    });
  }

  navigateBack(): void {
    this.router.navigate(['/teacher/progress']);
  }

  getProgressColor(progress: number): string {
    if (progress >= 80) return '#10b981'; // green
    if (progress >= 50) return '#f59e0b'; // yellow
    return '#ef4444'; // red
  }

  getRatingStars(rating?: number): string {
    if (!rating) return 'Non noté';
    return '⭐'.repeat(Math.round(rating));
  }

  getCompletedCount(): number {
    return this.students().filter(s => s.completed).length;
  }

  getAverageProgress(): number {
    const studentsList = this.students();
    if (studentsList.length === 0) return 0;
    const total = studentsList.reduce((sum, s) => sum + s.progress, 0);
    return total / studentsList.length;
  }

  getAverageProgressFormatted(): string {
    return this.getAverageProgress().toFixed(1);
  }

  formatProgress(progress: number): string {
    return progress.toFixed(1);
  }

  formatRating(rating: number): string {
    return rating.toFixed(1);
  }

  resetQuizAttempts(studentId: number): void {
    if (!this.courseId() || !studentId) {
      console.error('Invalid courseId or studentId');
      return;
    }

    const confirmed = confirm(
      `Êtes-vous sûr de vouloir réinitialiser toutes les tentatives de quiz pour cet étudiant ?\n\n` +
      `Cette action supprimera toutes les tentatives de quiz de l'étudiant pour ce cours et lui permettra de refaire les quiz.`
    );

    if (!confirmed) {
      return;
    }

    this.courseService.resetStudentQuizAttempts(this.courseId()!, studentId).subscribe({
      next: () => {
        alert('Les tentatives de quiz ont été réinitialisées avec succès. L\'étudiant peut maintenant refaire les quiz.');
        console.log('Quiz attempts reset successfully for student:', studentId);
      },
      error: (error: any) => {
        console.error('Error resetting quiz attempts', error);
        if (error.status === 404) {
          alert('Aucun quiz trouvé pour ce cours.');
        } else if (error.status === 403) {
          alert('Vous n\'êtes pas autorisé à effectuer cette action.');
        } else {
          alert('Erreur lors de la réinitialisation des tentatives. Veuillez réessayer.');
        }
      }
    });
  }

  resetStudentProgress(studentId: number): void {
    if (!this.courseId() || !studentId) {
      console.error('Invalid courseId or studentId');
      return;
    }

    const student = this.students().find(s => s.studentId === studentId);
    const studentName = student ? student.fullName : 'cet étudiant';

    const confirmed = confirm(
      `Êtes-vous sûr de vouloir réinitialiser la progression de ${studentName} à 0% ?\n\n` +
      `Cette action remettra la progression du cours à 0% et marquera le cours comme non complété. ` +
      `L'étudiant pourra recommencer le cours depuis le début.`
    );

    if (!confirmed) {
      return;
    }

    this.courseService.resetStudentProgress(this.courseId()!, studentId).subscribe({
      next: () => {
        alert(`La progression de ${studentName} a été réinitialisée avec succès à 0%. L'étudiant peut maintenant recommencer le cours.`);
        console.log('Student progress reset successfully for student:', studentId);
        // Recharger la progression pour mettre à jour l'affichage
        this.loadStudentProgress();
      },
      error: (error: any) => {
        console.error('Error resetting student progress', error);
        if (error.status === 404) {
          alert('Inscription de l\'étudiant non trouvée.');
        } else if (error.status === 403) {
          alert('Vous n\'êtes pas autorisé à effectuer cette action.');
        } else {
          alert('Erreur lors de la réinitialisation de la progression. Veuillez réessayer.');
        }
      }
    });
  }
}
