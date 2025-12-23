import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { Review } from '../models/review.model';

@Injectable({
  providedIn: 'root'
})
export class ReviewService {
  private readonly baseUrl = 'http://localhost:8080';

  constructor(private http: HttpClient) {}

  addReview(courseId: number, rating: number, comment: string): Observable<Review> {
    return this.http.post<Review>(`${this.baseUrl}/student/courses/${courseId}/reviews`, {
      rating,
      comment
    });
  }

  getCourseReviews(courseId: number): Observable<Review[]> {
    return this.http.get<Review[]>(`${this.baseUrl}/student/courses/${courseId}/reviews`);
  }

  // =================== PROFESSEUR ===================

  getPendingReviews(): Observable<Review[]> {
    return this.http.get<Review[]>(`${this.baseUrl}/teacher/reviews/pending`);
  }

  approveReview(reviewId: number): Observable<void> {
    return this.http.put<void>(`${this.baseUrl}/teacher/reviews/${reviewId}/approve`, {});
  }

  rejectReview(reviewId: number): Observable<void> {
    return this.http.put<void>(`${this.baseUrl}/teacher/reviews/${reviewId}/reject`, {});
  }
}








