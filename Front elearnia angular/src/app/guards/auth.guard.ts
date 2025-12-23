import { inject } from '@angular/core';
import { Router, CanActivateFn } from '@angular/router';
import { AuthService } from '../services/auth.service';

export const authGuard: CanActivateFn = (route, state) => {
  const authService = inject(AuthService);
  const router = inject(Router);

  if (authService.isAuthenticated()) {
    return true;
  }

  router.navigate(['/login']);
  return false;
};

export const teacherGuard: CanActivateFn = (route, state) => {
  const authService = inject(AuthService);
  const router = inject(Router);

  const isAuthenticated = authService.isAuthenticated();
  const isTeacher = authService.isTeacher();
  const currentUser = authService.getCurrentUser();

  console.log('TeacherGuard check:', { isAuthenticated, isTeacher, currentUser, url: state.url });

  if (isAuthenticated && isTeacher) {
    return true;
  }

  console.warn('TeacherGuard: Access denied', { isAuthenticated, isTeacher, currentUser });
  
  // Si pas authentifié, rediriger vers login
  if (!isAuthenticated) {
    router.navigate(['/login']);
  } else {
    // Si authentifié mais pas enseignant, rediriger vers la page d'accueil appropriée
    router.navigate(['/']);
  }
  return false;
};

export const studentGuard: CanActivateFn = (route, state) => {
  const authService = inject(AuthService);
  const router = inject(Router);

  if (authService.isAuthenticated() && authService.isStudent()) {
    return true;
  }

  router.navigate(['/']);
  return false;
};



