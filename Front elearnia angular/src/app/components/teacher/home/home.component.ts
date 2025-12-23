import { Component, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router, RouterModule } from '@angular/router';
import { AuthService } from '../../../services/auth.service';
import { User } from '../../../models/user.model';

@Component({
  selector: 'app-teacher-home',
  standalone: true,
  imports: [CommonModule, RouterModule],
  templateUrl: './home.component.html',
  styleUrl: './home.component.css'
})
export class TeacherHomeComponent implements OnInit {
  user: User | null = null;

  constructor(
    private authService: AuthService,
    private router: Router
  ) {}

  ngOnInit(): void {
    this.user = this.authService.getCurrentUser();
  }

  navigateToCourses(): void {
    this.router.navigate(['/teacher/courses']);
  }

  navigateToCreateCourse(): void {
    this.router.navigate(['/teacher/course/create']);
  }

  navigateToAnalytics(): void {
    this.router.navigate(['/teacher/analytics']);
  }

  navigateToProgress(): void {
    this.router.navigate(['/teacher/progress']);
  }

  navigateToAIGenerator(): void {
    this.router.navigate(['/teacher/ai-generator']);
  }

  navigateToGenerateQuiz(): void {
    this.router.navigate(['/teacher/generate-quiz']);
  }

  navigateToQuizzes(): void {
    this.router.navigate(['/teacher/quizzes']);
  }

  navigateToProfile(): void {
    this.router.navigate(['/teacher/profile']);
  }

  logout(): void {
    this.authService.logout();
    this.router.navigate(['/login']);
  }
}

