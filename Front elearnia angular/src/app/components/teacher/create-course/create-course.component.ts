import { Component, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, FormGroup, Validators, ReactiveFormsModule } from '@angular/forms';
import { Router, RouterModule } from '@angular/router';
import { CourseService } from '../../../services/course.service';
import { FileUploadService } from '../../../services/file-upload.service';

@Component({
  selector: 'app-create-course',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, RouterModule],
  templateUrl: './create-course.component.html',
  styleUrl: './create-course.component.css'
})
export class CreateCourseComponent {
  courseForm: FormGroup;
  isSubmitting = signal(false);
  selectedFile: File | null = null;
  imagePreview = signal<string | null>(null);

  constructor(
    private fb: FormBuilder,
    private courseService: CourseService,
    private fileUploadService: FileUploadService,
    private router: Router
  ) {
    this.courseForm = this.fb.group({
      title: ['', [Validators.required, Validators.minLength(3)]],
      description: ['', [Validators.required, Validators.minLength(10)]],
      imageUrl: ['']
    });
  }

  onFileSelected(event: any): void {
    const file = event.target.files[0];
    if (file) {
      this.selectedFile = file;
      const reader = new FileReader();
      reader.onload = () => {
        this.imagePreview.set(reader.result as string);
      };
      reader.readAsDataURL(file);
    }
  }

  onSubmit(): void {
    if (this.courseForm.valid) {
      this.isSubmitting.set(true);
      
      if (this.selectedFile) {
        this.fileUploadService.uploadImage(this.selectedFile).subscribe({
          next: (response) => {
            this.createCourse(response.url);
          },
          error: (error: any) => {
            console.error('Error uploading image', error);
            this.createCourse();
          }
        });
      } else {
        this.createCourse();
      }
    }
  }

  private createCourse(imageUrl?: string): void {
    const formValue = this.courseForm.value;
    this.courseService.createCourse(formValue.title, formValue.description, imageUrl).subscribe({
      next: () => {
        this.router.navigate(['/teacher/courses']);
      },
      error: (error: any) => {
        console.error('Error creating course', error);
        this.isSubmitting.set(false);
      }
    });
  }
}

