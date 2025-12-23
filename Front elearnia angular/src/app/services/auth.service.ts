import { Injectable, signal } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, BehaviorSubject, of } from 'rxjs';
import { map, tap, catchError } from 'rxjs/operators';
import { User, AuthResponse } from '../models/user.model';

@Injectable({
  providedIn: 'root'
})
export class AuthService {
  private readonly baseUrl = 'http://localhost:8080';
  private readonly tokenKey = 'auth_token';
  private readonly userKey = 'auth_user';
  
  private currentUserSubject = new BehaviorSubject<User | null>(null);
  public currentUser$ = this.currentUserSubject.asObservable();

  constructor(private http: HttpClient) {
    this.loadStoredUser();
  }

  private loadStoredUser(): void {
    const token = localStorage.getItem(this.tokenKey);
    const userStr = localStorage.getItem(this.userKey);
    if (token && userStr) {
      try {
        const user = JSON.parse(userStr);
        this.currentUserSubject.next(user);
      } catch (e) {
        console.error('Error parsing stored user', e);
      }
    }
  }

  register(fullName: string, email: string, password: string, role: string): Observable<AuthResponse> {
    return this.http.post<any>(`${this.baseUrl}/auth/register`, {
      fullName,
      email,
      password,
      role
    }).pipe(
      map((backendResponse: any) => {
        // Transformer la réponse du backend en structure attendue par le frontend
        const authResponse: AuthResponse = {
          token: backendResponse.token,
          user: {
            id: undefined, // Le backend ne retourne pas l'id dans AuthResponse
            fullName: backendResponse.fullName,
            email: backendResponse.email,
            role: backendResponse.role
          }
        };
        return authResponse;
      }),
      tap(response => {
        this.storeAuth(response);
      })
    );
  }

  login(email: string, password: string): Observable<AuthResponse> {
    return this.http.post<any>(`${this.baseUrl}/auth/login`, {
      email,
      password
    }).pipe(
      map((backendResponse: any) => {
        // Transformer la réponse du backend en structure attendue par le frontend
        const authResponse: AuthResponse = {
          token: backendResponse.token,
          user: {
            id: undefined, // Le backend ne retourne pas l'id dans AuthResponse
            fullName: backendResponse.fullName,
            email: backendResponse.email,
            role: backendResponse.role
          }
        };
        return authResponse;
      }),
      tap(response => {
        this.storeAuth(response);
      })
    );
  }

  logout(): void {
    localStorage.removeItem(this.tokenKey);
    localStorage.removeItem(this.userKey);
    this.currentUserSubject.next(null);
  }

  getToken(): string | null {
    return localStorage.getItem(this.tokenKey);
  }

  getCurrentUser(): User | null {
    return this.currentUserSubject.value;
  }

  isAuthenticated(): boolean {
    return !!this.getToken();
  }

  isTeacher(): boolean {
    const user = this.getCurrentUser();
    if (!user?.role) return false;
    const role = user.role.toUpperCase().replace('ROLE_', '');
    return role === 'TEACHER';
  }

  isStudent(): boolean {
    const user = this.getCurrentUser();
    if (!user?.role) return false;
    const role = user.role.toUpperCase().replace('ROLE_', '');
    return role === 'LEARNER';
  }

  updateProfile(fullName: string, email: string): Observable<User> {
    const token = this.getToken();
    if (!token) {
      throw new Error('No token available');
    }
    
    // Sauvegarder la biographie actuelle avant la mise à jour
    const currentUser = this.getCurrentUser();
    const currentBiography = currentUser?.biography;
    
    return this.http.put<User>(`${this.baseUrl}/auth/profile`, {
      fullName,
      email
    }, {
      headers: {
        'Authorization': `Bearer ${token}`
      }
    }).pipe(
      tap((updatedUser: User) => {
        // Préserver la biographie si elle existait
        const userWithBio = {
          ...updatedUser,
          biography: currentBiography || updatedUser.biography
        };
        // Mettre à jour l'utilisateur stocké
        localStorage.setItem(this.userKey, JSON.stringify(userWithBio));
        this.currentUserSubject.next(userWithBio);
      })
    );
  }

  private storeAuth(response: AuthResponse): void {
    localStorage.setItem(this.tokenKey, response.token);
    localStorage.setItem(this.userKey, JSON.stringify(response.user));
    this.currentUserSubject.next(response.user);
  }
}


