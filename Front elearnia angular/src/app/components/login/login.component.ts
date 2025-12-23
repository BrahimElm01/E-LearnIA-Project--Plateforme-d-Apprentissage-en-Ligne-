import { Component, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, FormGroup, Validators, ReactiveFormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { AuthService } from '../../services/auth.service';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule],
  templateUrl: './login.component.html',
  styleUrl: './login.component.css'
})
export class LoginComponent {
  loginForm: FormGroup;
  isLoading = signal(false);
  selectedRole = signal<'LEARNER' | 'TEACHER'>('LEARNER');
  errorMessage = signal<string | null>(null);

  constructor(
    private fb: FormBuilder,
    private authService: AuthService,
    private router: Router
  ) {
    this.loginForm = this.fb.group({
      email: ['', [Validators.required, Validators.email]],
      password: ['', [Validators.required, Validators.minLength(6)]]
    });
  }

  onSubmit(): void {
    if (this.loginForm.valid) {
      this.isLoading.set(true);
      this.errorMessage.set(null);

      const { email, password } = this.loginForm.value;

      this.authService.login(email, password).subscribe({
        next: (response) => {
          this.isLoading.set(false);
          const user = response.user;
          
          // Vérifier la cohérence du rôle
          if (!this.checkRoleConsistency(user)) {
            return;
          }

          // Rediriger selon le rôle
          this.navigateToHome(user);
        },
        error: (error) => {
          console.error('Login error:', error);
          this.errorMessage.set(error.error?.message || 'Erreur de connexion');
          this.isLoading.set(false);
        }
      });
    }
  }

  private checkRoleConsistency(user: any): boolean {
    const userRole = user.role?.toUpperCase() || '';
    const selectedRole = this.selectedRole().toUpperCase();
    
    // Normaliser le rôle utilisateur (enlever le préfixe ROLE_ si présent)
    const normalizedUserRole = userRole.replace('ROLE_', '');
    
    if (normalizedUserRole !== selectedRole) {
      const roleName = normalizedUserRole === 'TEACHER' ? 'Professeur' : 'Étudiant';
      this.errorMessage.set(`Ce compte est un compte ${roleName}. Veuillez sélectionner le bon rôle.`);
      return false;
    }
    return true;
  }

  private navigateToHome(user: any): void {
    const role = (user.role?.toUpperCase() || '').replace('ROLE_', '');
    if (role === 'TEACHER') {
      this.router.navigate(['/teacher/home']);
    } else {
      this.router.navigate(['/student/home']);
    }
  }

  navigateToRegister(): void {
    this.router.navigate(['/register']);
  }
}


