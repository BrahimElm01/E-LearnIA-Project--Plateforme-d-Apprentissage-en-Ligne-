import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { Quiz, QuizSummary, QuizResult } from '../models/quiz.model';

@Injectable({
  providedIn: 'root'
})
export class QuizService {
  private readonly baseUrl = 'http://localhost:8080';

  constructor(private http: HttpClient) {}

  getQuizByCourse(courseId: number): Observable<Quiz> {
    return this.http.get<Quiz>(`${this.baseUrl}/student/quizzes/course/${courseId}`);
  }

  getLessonQuiz(courseId: number, lessonId: number): Observable<Quiz> {
    return this.http.get<Quiz>(`${this.baseUrl}/student/courses/${courseId}/lessons/${lessonId}/quiz`);
  }

  submitQuiz(courseId: number, answers: Map<number, string>): Observable<QuizResult> {
    const answersObj: { [key: string]: string } = {};
    answers.forEach((value, key) => {
      answersObj[key.toString()] = value;
    });
    return this.http.post<QuizResult>(`${this.baseUrl}/student/quizzes/course/${courseId}/submit`, {
      answers: answersObj
    });
  }

  getAvailableQuizzes(level?: string): Observable<QuizSummary[]> {
    let params = new HttpParams();
    // Ne pas envoyer le paramètre level si c'est 'ALL' ou undefined
    if (level && level !== 'ALL' && level.trim() !== '') {
      params = params.set('level', level);
    }
    return this.http.get<QuizSummary[]>(`${this.baseUrl}/student/quizzes/available`, { params });
  }

  getStandaloneQuiz(quizId: number): Observable<Quiz> {
    return this.http.get<Quiz>(`${this.baseUrl}/student/quizzes/${quizId}`);
  }

  submitStandaloneQuiz(quizId: number, answers: Map<number, string>): Observable<QuizResult> {
    const answersObj: { [key: string]: string } = {};
    answers.forEach((value, key) => {
      answersObj[key.toString()] = value;
    });
    return this.http.post<QuizResult>(`${this.baseUrl}/student/quizzes/${quizId}/submit`, {
      answers: answersObj
    });
  }

  // =================== PROFESSEUR ===================

  createStandaloneQuiz(quiz: any): Observable<Quiz> {
    return this.http.post<Quiz>(`${this.baseUrl}/teacher/courses/quiz`, quiz);
  }

  generateQuizWithAI(topic: string, difficulty: string, numberOfQuestions?: number): Observable<Quiz> {
    const body: any = { topic, difficulty };
    if (numberOfQuestions) body.numberOfQuestions = numberOfQuestions;
    return this.http.post<Quiz>(`${this.baseUrl}/teacher/courses/quiz/generate`, body);
  }

  getQuizScoresForCourse(courseId: number): Observable<any> {
    return this.http.get<any>(`${this.baseUrl}/teacher/courses/${courseId}/quiz/scores`);
  }

  getAllQuizzesScores(): Observable<any> {
    return this.http.get<any>(`${this.baseUrl}/teacher/courses/quizzes/scores`);
  }

  resetQuizAttempts(userId: number, quizId: number): Observable<void> {
    return this.http.delete<void>(`${this.baseUrl}/teacher/quizzes/${quizId}/attempts/${userId}`);
  }

  getTeacherQuizzes(): Observable<Quiz[]> {
    return this.http.get<Quiz[]>(`${this.baseUrl}/teacher/courses/quizzes`);
  }

  getStandaloneQuizForTeacher(quizId: number): Observable<Quiz> {
    return this.http.get<Quiz>(`${this.baseUrl}/teacher/courses/quiz/${quizId}`);
  }

  updateStandaloneQuiz(quizId: number, quiz: any): Observable<Quiz> {
    return this.http.put<Quiz>(`${this.baseUrl}/teacher/courses/quiz/${quizId}`, quiz);
  }

  deleteStandaloneQuiz(quizId: number): Observable<void> {
    return this.http.delete<void>(`${this.baseUrl}/teacher/courses/quiz/${quizId}`);
  }

  // Méthodes pour les quizzes liés aux cours
  getCourseQuiz(courseId: number): Observable<Quiz> {
    return this.http.get<Quiz>(`${this.baseUrl}/teacher/courses/${courseId}/quiz`);
  }

  updateCourseQuiz(courseId: number, quiz: any): Observable<Quiz> {
    return this.http.put<Quiz>(`${this.baseUrl}/teacher/courses/${courseId}/quiz`, quiz);
  }

  deleteCourseQuiz(courseId: number): Observable<void> {
    return this.http.delete<void>(`${this.baseUrl}/teacher/courses/${courseId}/quiz`);
  }
}



