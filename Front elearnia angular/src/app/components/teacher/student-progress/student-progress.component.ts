import { Component, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router, RouterModule } from '@angular/router';
import { CourseService } from '../../../services/course.service';

@Component({
  selector: 'app-student-progress',
  standalone: true,
  imports: [CommonModule, RouterModule],
  templateUrl: './student-progress.component.html',
  styleUrl: './student-progress.component.css'
})
export class StudentProgressComponent implements OnInit {
  isLoading = signal(false);
  courses = signal<any[]>([]);

  constructor(
    private courseService: CourseService,
    private router: Router
  ) {}

  ngOnInit(): void {
    this.loadCourses();
  }

  loadCourses(): void {
    this.isLoading.set(true);
    this.courseService.getTeacherCourses().subscribe({
      next: (courses) => {
        this.courses.set(courses);
        this.isLoading.set(false);
      },
      error: (error: any) => {
        console.error('Error loading courses', error);
        this.isLoading.set(false);
      }
    });
  }

  navigateToHome(): void {
    this.router.navigate(['/teacher/home']);
  }

  viewCourseProgress(courseId: number): void {
    console.log('Navigating to progress for course:', courseId);
    if (!courseId || isNaN(courseId)) {
      console.error('Invalid courseId:', courseId);
      alert('ID de cours invalide');
      return;
    }
    // Utiliser navigateByUrl pour être plus explicite
    const url = `/teacher/progress/${courseId}`;
    console.log('Navigating to URL:', url);
    this.router.navigateByUrl(url).then(
      (success) => {
        if (success) {
          console.log('Navigation successful');
        } else {
          console.error('Navigation failed');
          alert('Erreur lors de la navigation. Vérifiez que vous êtes connecté en tant qu\'enseignant.');
        }
      }
    ).catch((error) => {
      console.error('Navigation error:', error);
      alert('Erreur lors de la navigation: ' + error);
    });
  }
}


