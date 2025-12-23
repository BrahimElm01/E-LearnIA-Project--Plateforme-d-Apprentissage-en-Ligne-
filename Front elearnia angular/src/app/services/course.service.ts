import { Injectable } from '@angular/core';
import { HttpClient, HttpErrorResponse } from '@angular/common/http';
import { Observable, throwError } from 'rxjs';
import { map, catchError } from 'rxjs/operators';
import { StudentCourse, TeacherCourse, Course, CourseAnalytics, StudentProgress } from '../models/course.model';
import { Lesson } from '../models/lesson.model';
import { Quiz } from '../models/quiz.model';
import { GeneratedCourse } from '../models/generated-course.model';
import { AuthService } from './auth.service';

@Injectable({
  providedIn: 'root'
})
export class CourseService {
  private readonly baseUrl = 'http://localhost:8080';

  constructor(
    private http: HttpClient,
    private authService: AuthService
  ) {}

  // =================== ÉTUDIANT ===================

  enrollToCourse(courseId: number): Observable<any> {
    return this.http.post<any>(`${this.baseUrl}/student/courses/${courseId}/enroll`, {});
  }

  getStudentCourses(): Observable<StudentCourse[]> {
    return this.http.get<any[]>(`${this.baseUrl}/student/courses`).pipe(
      map(courses => courses.map(c => this.mapToStudentCourse(c)))
    );
  }

  getCourseDetails(courseId: number): Observable<Course> {
    return this.http.get<Course>(`${this.baseUrl}/student/courses/${courseId}`);
  }

  getCourseLessons(courseId: number): Observable<Lesson[]> {
    return this.http.get<Lesson[]>(`${this.baseUrl}/student/courses/${courseId}/lessons`);
  }

  updateProgress(courseId: number, progress: number, completed?: boolean): Observable<any> {
    const body: any = { progress };
    if (completed !== undefined) {
      body.completed = completed;
    }
    return this.http.put(`${this.baseUrl}/student/courses/${courseId}/progress`, body);
  }

  getCourseReviews(courseId: number): Observable<any[]> {
    return this.http.get<any[]>(`${this.baseUrl}/student/courses/${courseId}/reviews`);
  }

  addCourseReview(courseId: number, rating: number, comment: string): Observable<any> {
    return this.http.post<any>(`${this.baseUrl}/student/courses/${courseId}/reviews`, {
      rating,
      comment
    });
  }

  getLessonQuiz(courseId: number, lessonId: number): Observable<any> {
    return this.http.get<any>(`${this.baseUrl}/student/courses/${courseId}/lessons/${lessonId}/quiz`);
  }

  // =================== PROFESSEUR ===================

  getTeacherCourses(): Observable<TeacherCourse[]> {
    const token = this.authService.getToken();
    console.log('Making request to:', `${this.baseUrl}/teacher/courses/my`);
    console.log('Token available:', !!token);
    if (token) {
      console.log('Token preview:', token.substring(0, 20) + '...');
    }
    
    return this.http.get<any[]>(`${this.baseUrl}/teacher/courses/my`).pipe(
      map(courses => {
        console.log('Raw courses from backend:', courses);
        if (!courses) {
          console.warn('Backend returned null or undefined');
          return [];
        }
        if (!Array.isArray(courses)) {
          console.warn('Backend did not return an array:', typeof courses);
          return [];
        }
        const mapped = courses.map(c => this.mapToTeacherCourse(c));
        console.log('Mapped courses:', mapped);
        return mapped;
      }),
      catchError((error: HttpErrorResponse) => {
        console.error('HTTP Error in getTeacherCourses:', error);
        return throwError(() => error);
      })
    );
  }

  createCourse(title: string, description: string, imageUrl?: string): Observable<TeacherCourse> {
    return this.http.post<any>(`${this.baseUrl}/teacher/courses`, {
      title,
      description,
      imageUrl
    }).pipe(
      map(c => this.mapToTeacherCourse(c))
    );
  }

  getTeacherCourseById(courseId: number): Observable<TeacherCourse> {
    return this.http.get<any>(`${this.baseUrl}/teacher/courses/${courseId}`).pipe(
      map(c => this.mapToTeacherCourse(c))
    );
  }

  updateCourse(courseId: number, title: string, description: string, imageUrl?: string, published?: boolean): Observable<TeacherCourse> {
    const body: any = {
      title,
      description
    };
    if (imageUrl !== undefined) {
      body.imageUrl = imageUrl;
    }
    if (published !== undefined) {
      body.published = published;
    }
    return this.http.put<any>(`${this.baseUrl}/teacher/courses/${courseId}`, body).pipe(
      map(c => this.mapToTeacherCourse(c))
    );
  }

  deleteCourse(courseId: number): Observable<void> {
    return this.http.delete<void>(`${this.baseUrl}/teacher/courses/${courseId}`);
  }

  getCourseLessonsForTeacher(courseId: number): Observable<Lesson[]> {
    return this.http.get<Lesson[]>(`${this.baseUrl}/teacher/courses/${courseId}/lessons`);
  }

  addLesson(courseId: number, lesson: Partial<Lesson>): Observable<Lesson> {
    return this.http.post<Lesson>(`${this.baseUrl}/teacher/courses/${courseId}/lessons`, lesson);
  }

  updateLesson(courseId: number, lessonId: number, lesson: Partial<Lesson>): Observable<Lesson> {
    return this.http.put<Lesson>(`${this.baseUrl}/teacher/courses/${courseId}/lessons/${lessonId}`, lesson);
  }

  deleteLesson(courseId: number, lessonId: number): Observable<void> {
    return this.http.delete<void>(`${this.baseUrl}/teacher/courses/${courseId}/lessons/${lessonId}`);
  }

  // Gestion des quizzes des leçons (pour professeur)
  getLessonQuizForTeacher(courseId: number, lessonId: number): Observable<any> {
    return this.http.get<any>(`${this.baseUrl}/teacher/courses/${courseId}/lessons/${lessonId}/quiz`);
  }

  assignQuizToLesson(courseId: number, lessonId: number, quizId: number): Observable<any> {
    return this.http.put<any>(`${this.baseUrl}/teacher/courses/${courseId}/lessons/${lessonId}/quiz/${quizId}`, {});
  }

  removeQuizFromLesson(courseId: number, lessonId: number): Observable<void> {
    return this.http.delete<void>(`${this.baseUrl}/teacher/courses/${courseId}/lessons/${lessonId}/quiz`);
  }

  getCourseAnalytics(): Observable<CourseAnalytics> {
    return this.http.get<CourseAnalytics>(`${this.baseUrl}/teacher/courses/analytics`);
  }

  getStudentProgress(courseId: number): Observable<StudentProgress[]> {
    return this.http.get<StudentProgress[]>(`${this.baseUrl}/teacher/courses/${courseId}/students-progress`);
  }

  resetStudentQuizAttempts(courseId: number, studentId: number): Observable<void> {
    return this.http.delete<void>(`${this.baseUrl}/teacher/courses/${courseId}/students/${studentId}/quiz-attempts`);
  }

  resetStudentProgress(courseId: number, studentId: number): Observable<void> {
    return this.http.put<void>(`${this.baseUrl}/teacher/courses/${courseId}/students/${studentId}/reset-progress`, {});
  }

  // =================== IA ===================

  generateCourseWithAI(idea: string, level?: string): Observable<GeneratedCourse> {
    const body: any = { idea };
    if (level) body.level = level;
    return this.http.post<GeneratedCourse>(`${this.baseUrl}/teacher/courses/generate`, body);
  }

  generateAndCreateCourse(idea: string, level?: string): Observable<TeacherCourse> {
    const body: any = { idea };
    if (level) body.level = level;
    return this.http.post<any>(`${this.baseUrl}/teacher/courses/generate-and-create`, body).pipe(
      map(c => this.mapToTeacherCourse(c))
    );
  }

  // =================== HELPERS ===================

  private mapToStudentCourse(json: any): StudentCourse {
    const teacher = json.teacher || {};
    return {
      id: json.id || 0,
      title: json.title || '',
      description: json.description || '',
      teacherName: teacher.fullName || '',
      imageUrl: json.imageUrl,
      progress: json.progress || 0,
      completed: json.completed || false
    };
  }

  private mapToTeacherCourse(json: any): TeacherCourse {
    return {
      id: json.id || 0,
      title: json.title || '',
      description: json.description || '',
      published: json.published || json.published === 1 || false,
      imageUrl: json.imageUrl || json.image_url || null
    };
  }
}


