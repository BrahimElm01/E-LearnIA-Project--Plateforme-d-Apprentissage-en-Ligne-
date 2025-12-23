import { Component, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router, RouterModule } from '@angular/router';
import { forkJoin, of } from 'rxjs';
import { catchError } from 'rxjs/operators';
import { CourseService } from '../../../services/course.service';
import { QuizService } from '../../../services/quiz.service';
import { CourseAnalytics, TeacherCourse, StudentProgress } from '../../../models/course.model';
import { Quiz } from '../../../models/quiz.model';

interface DashboardStats {
  totalStudents: number;
  activeCourses: number;
  totalQuizzes: number;
  averageRating: number;
  totalEnrollments: number;
  completedCourses: number;
  averageProgress: number;
}

interface CourseStats {
  course: TeacherCourse;
  enrollments: number;
  averageProgress: number;
  completed: number;
  averageRating: number;
}

interface QuizStats {
  quiz: Quiz;
  totalAttempts: number;
  averageScore: number;
  passed: number;
  failed: number;
}

@Component({
  selector: 'app-analytics',
  standalone: true,
  imports: [CommonModule, RouterModule],
  templateUrl: './analytics.component.html',
  styleUrl: './analytics.component.css'
})
export class AnalyticsComponent implements OnInit {
  analytics = signal<CourseAnalytics | null>(null);
  dashboardStats = signal<DashboardStats | null>(null);
  courses = signal<TeacherCourse[]>([]);
  quizzes = signal<Quiz[]>([]);
  courseStats = signal<CourseStats[]>([]);
  quizStats = signal<any[]>([]);
  allStudentProgress = signal<StudentProgress[]>([]);
  isLoading = signal(false);
  errorMessage = signal<string | null>(null);

  constructor(
    private courseService: CourseService,
    private quizService: QuizService,
    private router: Router
  ) {}

  ngOnInit(): void {
    this.loadDashboardData();
  }

  loadDashboardData(): void {
    this.isLoading.set(true);
    this.errorMessage.set(null);

    // Charger toutes les données en parallèle
    forkJoin({
      analytics: this.courseService.getCourseAnalytics().pipe(
        catchError(() => of(null))
      ),
      courses: this.courseService.getTeacherCourses().pipe(
        catchError(() => of([]))
      ),
      quizzes: this.quizService.getTeacherQuizzes().pipe(
        catchError(() => of([]))
      ),
      quizScores: this.quizService.getAllQuizzesScores().pipe(
        catchError(() => of([]))
      )
    }).subscribe({
      next: ({ analytics, courses, quizzes, quizScores }) => {
        this.analytics.set(analytics);
        this.courses.set(courses || []);
        this.quizzes.set(quizzes || []);

        // Calculer les statistiques du dashboard
        this.calculateDashboardStats(courses, quizzes, quizScores);
        
        // Charger les statistiques détaillées par cours
        this.loadCourseStats(courses);
        
        // Charger les statistiques des quizzes
        this.loadQuizStats(quizzes, quizScores);

        this.isLoading.set(false);
      },
      error: (error) => {
        console.error('Error loading dashboard data', error);
        this.errorMessage.set('Erreur lors du chargement des données');
        this.isLoading.set(false);
      }
    });
  }

  calculateDashboardStats(courses: TeacherCourse[], quizzes: Quiz[], quizScores: any[]): void {
    const totalStudents = this.analytics()?.totalStudents || 0;
    const activeCourses = courses?.length || 0;
    const totalQuizzes = quizzes?.length || 0;
    const averageRating = this.analytics()?.averageRating || 0;

    // Charger toutes les progressions en parallèle
    if (courses && courses.length > 0) {
      const progressObservables = courses.map(course =>
        this.courseService.getStudentProgress(course.id).pipe(
          catchError(() => of([]))
        )
      );

      forkJoin(progressObservables).subscribe({
        next: (allProgress: StudentProgress[][]) => {
          let totalEnrollments = 0;
          let completedCourses = 0;
          let totalProgress = 0;
          let progressCount = 0;
          const allStudents: StudentProgress[] = [];

          allProgress.forEach(progress => {
            totalEnrollments += progress.length;
            progress.forEach(p => {
              if (p.completed) completedCourses++;
              totalProgress += p.progress;
              progressCount++;
              allStudents.push(p);
            });
          });

          this.allStudentProgress.set(allStudents);

          const averageProgress = progressCount > 0 ? totalProgress / progressCount : 0;

          this.dashboardStats.set({
            totalStudents,
            activeCourses,
            totalQuizzes,
            averageRating,
            totalEnrollments,
            completedCourses,
            averageProgress
          });
        }
      });
    } else {
      this.dashboardStats.set({
        totalStudents,
        activeCourses,
        totalQuizzes,
        averageRating,
        totalEnrollments: 0,
        completedCourses: 0,
        averageProgress: 0
      });
    }
  }

  loadCourseStats(courses: TeacherCourse[]): void {
    if (!courses || courses.length === 0) {
      this.courseStats.set([]);
      return;
    }

    const progressObservables = courses.map(course =>
      this.courseService.getStudentProgress(course.id).pipe(
        catchError(() => of([]))
      )
    );

    forkJoin(progressObservables).subscribe({
      next: (allProgress: StudentProgress[][]) => {
        const stats: CourseStats[] = courses.map((course, index) => {
          const progress = allProgress[index] || [];
          const enrollments = progress.length;
          const completed = progress.filter(p => p.completed).length;
          const totalProgress = progress.reduce((sum, p) => sum + p.progress, 0);
          const averageProgress = enrollments > 0 ? totalProgress / enrollments : 0;
          const ratedProgress = progress.filter(p => p.rating);
          const totalRating = ratedProgress.reduce((sum, p) => sum + (p.rating || 0), 0);
          const averageRating = ratedProgress.length > 0 
            ? totalRating / ratedProgress.length 
            : 0;

          return {
            course,
            enrollments,
            averageProgress,
            completed,
            averageRating
          };
        });

        this.courseStats.set(stats);
      }
    });
  }

  loadQuizStats(quizzes: Quiz[], quizScores: any[]): void {
    const stats: any[] = [];

    quizzes?.forEach(quiz => {
      const quizScoreData = quizScores?.find(qs => qs.quizId === quiz.id);
      if (quizScoreData) {
        const scores = quizScoreData.scores || [];
        const totalAttempts = scores.length;
        const totalScore = scores.reduce((sum: number, s: any) => sum + (s.score || 0), 0);
        const averageScore = totalAttempts > 0 ? totalScore / totalAttempts : 0;
        const passed = scores.filter((s: any) => s.passed).length;
        const failed = totalAttempts - passed;

        stats.push({
          quiz,
          totalAttempts,
          averageScore,
          passed,
          failed
        });
      } else {
        stats.push({
          quiz,
          totalAttempts: 0,
          averageScore: 0,
          passed: 0,
          failed: 0
        });
      }
    });

    this.quizStats.set(stats);
  }

  navigateToHome(): void {
    this.router.navigate(['/teacher/home']);
  }

  navigateToCourse(courseId: number): void {
    this.router.navigate(['/teacher/course', courseId, 'edit']);
  }

  navigateToQuizzes(): void {
    this.router.navigate(['/teacher/quizzes']);
  }

  getProgressColor(progress: number): string {
    if (progress >= 80) return '#10b981';
    if (progress >= 50) return '#f59e0b';
    return '#ef4444';
  }

  getRatingColor(rating: number): string {
    if (rating >= 4) return '#10b981';
    if (rating >= 3) return '#f59e0b';
    return '#ef4444';
  }

  formatNumber(value: number): string {
    return value.toFixed(1);
  }

  getTopCourses(limit: number = 5): CourseStats[] {
    return [...this.courseStats()].sort((a, b) => b.enrollments - a.enrollments).slice(0, limit);
  }

  getTopQuizzes(limit: number = 5): any[] {
    return [...this.quizStats()].sort((a, b) => b.totalAttempts - a.totalAttempts).slice(0, limit);
  }

  getStudentsByProgress(): { label: string; count: number; color: string }[] {
    const students = this.allStudentProgress();
    const completed = students.filter(s => s.completed).length;
    const inProgress = students.filter(s => !s.completed && s.progress > 0).length;
    const notStarted = students.filter(s => !s.completed && s.progress === 0).length;

    return [
      { label: 'Terminés', count: completed, color: '#10b981' },
      { label: 'En cours', count: inProgress, color: '#f59e0b' },
      { label: 'Non commencés', count: notStarted, color: '#9ca3af' }
    ];
  }
}
