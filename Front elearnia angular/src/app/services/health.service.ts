import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, of } from 'rxjs';
import { catchError, map } from 'rxjs/operators';

@Injectable({
  providedIn: 'root'
})
export class HealthService {
  private readonly baseUrl = 'http://localhost:8080';

  constructor(private http: HttpClient) {}

  checkBackendHealth(): Observable<boolean> {
    // Essayer de se connecter - si on reçoit une réponse HTTP (même erreur), le backend est accessible
    return this.http.get(`${this.baseUrl}/auth/login`, { 
      observe: 'response'
    }).pipe(
      map(() => true), // Si succès, backend accessible
      catchError((error) => {
        // Si on reçoit une réponse HTTP (même 405, 400, etc.), le backend est accessible
        // Seule une erreur réseau (status 0) signifie que le backend n'est pas accessible
        if (error.status && error.status > 0) {
          console.log('Backend is accessible (received HTTP response)');
          return of(true); // Backend accessible
        }
        // Si status 0 ou undefined, backend inaccessible
        console.error('Backend not accessible - network error');
        return of(false);
      })
    );
  }
}

