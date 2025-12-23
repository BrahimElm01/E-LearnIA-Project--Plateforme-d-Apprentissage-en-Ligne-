import { Component, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router, RouterModule } from '@angular/router';
import { CourseService } from '../../../services/course.service';
import { AuthService } from '../../../services/auth.service';
import { StudentCourse } from '../../../models/course.model';
import { User } from '../../../models/user.model';

@Component({
  selector: 'app-analytics',
  standalone: true,
  imports: [CommonModule, RouterModule],
  templateUrl: './analytics.html',
  styleUrl: './analytics.css'
})
export class AnalyticsComponent implements OnInit {
  user: User | null = null;
  courses = signal<StudentCourse[]>([]);
  isLoading = signal(false);

  // Statistiques calculées
  totalCourses = signal(0);
  completedCourses = signal(0);
  inProgressCourses = signal(0);
  notStartedCourses = signal(0);
  averageProgress = signal(0);
  totalProgress = signal(0);

  constructor(
    private courseService: CourseService,
    private authService: AuthService,
    private router: Router
  ) {}

  ngOnInit(): void {
    this.user = this.authService.getCurrentUser();
    this.loadCourses();
  }

  loadCourses(): void {
    this.isLoading.set(true);
    this.courseService.getStudentCourses().subscribe({
      next: (courses) => {
        this.courses.set(courses);
        this.calculateStatistics(courses);
        this.isLoading.set(false);
      },
      error: (error: any) => {
        console.error('Error loading courses', error);
        this.isLoading.set(false);
      }
    });
  }

  calculateStatistics(courses: StudentCourse[]): void {
    const total = courses.length;
    const completed = courses.filter(c => {
      const progress = c.progress || 0;
      return progress >= 100;
    }).length;
    const inProgress = courses.filter(c => {
      const progress = c.progress || 0;
      return progress > 0 && progress < 100;
    }).length;
    const notStarted = courses.filter(c => {
      const progress = c.progress || 0;
      return progress === 0;
    }).length;
    
    const totalProgress = courses.reduce((sum, c) => sum + c.progress, 0);
    const average = total > 0 ? totalProgress / total : 0;

    this.totalCourses.set(total);
    this.completedCourses.set(completed);
    this.inProgressCourses.set(inProgress);
    this.notStartedCourses.set(notStarted);
    this.averageProgress.set(average);
    this.totalProgress.set(totalProgress);
  }

  getCompletionRate(): number {
    return this.totalCourses() > 0 
      ? (this.completedCourses() / this.totalCourses()) * 100 
      : 0;
  }

  getProgressColor(progress: number): string {
    if (progress >= 80) return '#10b981'; // green
    if (progress >= 50) return '#f59e0b'; // yellow
    return '#ef4444'; // red
  }

  navigateToHome(): void {
    this.router.navigate(['/student/home']);
  }

  navigateToCourses(): void {
    this.router.navigate(['/student/courses']);
  }

  formatProgress(progress: number): string {
    // Limiter la progression à 100% maximum
    const limitedProgress = Math.min(100, Math.max(0, progress));
    return limitedProgress.toFixed(1);
  }

  // Limiter la progression à 100% maximum pour l'affichage
  getLimitedProgress(progress: number): number {
    return Math.min(100, Math.max(0, progress));
  }

  navigateBack(): void {
    this.router.navigate(['/student/home']);
  }
}
