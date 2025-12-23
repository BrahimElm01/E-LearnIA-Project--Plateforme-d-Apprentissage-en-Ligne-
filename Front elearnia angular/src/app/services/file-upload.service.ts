import { Injectable } from '@angular/core';
import { HttpClient, HttpEvent, HttpErrorResponse } from '@angular/common/http';
import { Observable, throwError } from 'rxjs';
import { timeout, catchError } from 'rxjs/operators';

@Injectable({
  providedIn: 'root'
})
export class FileUploadService {
  private readonly baseUrl = 'http://localhost:8080';
  private readonly uploadTimeout = 300000; // 5 minutes pour les gros fichiers

  constructor(private http: HttpClient) {}

  uploadImage(file: File): Observable<{ url: string }> {
    const formData = new FormData();
    formData.append('file', file);
    return this.http.post<{ url: string }>(`${this.baseUrl}/api/files/upload-image`, formData)
      .pipe(
        timeout(this.uploadTimeout),
        catchError(this.handleError)
      );
  }

  uploadVideo(file: File): Observable<{ url: string }> {
    const formData = new FormData();
    formData.append('file', file);
    return this.http.post<{ url: string }>(`${this.baseUrl}/api/files/upload-video`, formData, {
      reportProgress: true
    })
      .pipe(
        timeout(this.uploadTimeout),
        catchError(this.handleError)
      ) as Observable<{ url: string }>;
  }

  private handleError(error: HttpErrorResponse | Error): Observable<never> {
    let errorMessage = 'Une erreur est survenue lors de l\'upload';
    
    if (error instanceof HttpErrorResponse) {
      if (error.status === 413 || error.status === 0) {
        errorMessage = error.error?.message || 'Le fichier est trop volumineux ou la connexion a été interrompue';
      } else if (error.status === 401 || error.status === 403) {
        errorMessage = 'Erreur d\'authentification. Veuillez vous reconnecter';
      } else if (error.error?.message) {
        errorMessage = error.error.message;
      }
    } else if (error.name === 'TimeoutError') {
      errorMessage = 'Le temps d\'upload a expiré. Veuillez réessayer avec un fichier plus petit';
    }
    
    return throwError(() => new Error(errorMessage));
  }

  getImageUrl(filename: string): string {
    return `${this.baseUrl}/api/files/images/${filename}`;
  }

  getVideoUrl(filename: string): string {
    return `${this.baseUrl}/api/files/videos/${filename}`;
  }

  /**
   * Normalise l'URL de l'image en remplaçant l'ancienne IP par localhost
   * pour éviter les erreurs de connexion timeout
   */
  normalizeImageUrl(url: string | null | undefined): string | null {
    if (!url) return null;
    // Remplacer l'ancienne IP hardcodée par localhost
    return url.replace(/http:\/\/192\.168\.\d+\.\d+:\d+\//g, 'http://localhost:8080/');
  }
}




