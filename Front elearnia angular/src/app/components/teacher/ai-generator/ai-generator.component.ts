import { Component, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, FormGroup, Validators, ReactiveFormsModule } from '@angular/forms';
import { Router, RouterModule } from '@angular/router';
import { CourseService } from '../../../services/course.service';
import { GeneratedCourse } from '../../../models/generated-course.model';

@Component({
  selector: 'app-ai-generator',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, RouterModule],
  templateUrl: './ai-generator.component.html',
  styleUrl: './ai-generator.component.css'
})
export class AIGeneratorComponent {
  form: FormGroup;
  generatedCourse = signal<GeneratedCourse | null>(null);
  isGenerating = signal(false);
  isCreating = signal(false);

  constructor(
    private fb: FormBuilder,
    private courseService: CourseService,
    private router: Router
  ) {
    this.form = this.fb.group({
      idea: ['', [Validators.required, Validators.minLength(5)]],
      level: ['BEGINNER']
    });
  }

  generateCourse(): void {
    if (this.form.valid) {
      this.isGenerating.set(true);
      const { idea, level } = this.form.value;
      this.courseService.generateCourseWithAI(idea, level).subscribe({
        next: (course) => {
          this.generatedCourse.set(course);
          this.isGenerating.set(false);
        },
        error: (error: any) => {
          console.error('Error generating course', error);
          this.isGenerating.set(false);
        }
      });
    }
  }

  createCourse(): void {
    if (this.form.valid) {
      this.isCreating.set(true);
      const { idea, level } = this.form.value;
      this.courseService.generateAndCreateCourse(idea, level).subscribe({
        next: () => {
          this.router.navigate(['/teacher/courses']);
        },
        error: (error: any) => {
          console.error('Error creating course', error);
          this.isCreating.set(false);
        }
      });
    }
  }

  navigateToHome(): void {
    this.router.navigate(['/teacher/home']);
  }
}


