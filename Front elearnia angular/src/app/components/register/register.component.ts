import { Component, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, FormGroup, Validators, ReactiveFormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { AuthService } from '../../services/auth.service';

@Component({
  selector: 'app-register',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule],
  templateUrl: './register.component.html',
  styleUrl: './register.component.css'
})
export class RegisterComponent {
  registerForm: FormGroup;
  isLoading = signal(false);
  selectedRole = signal<'LEARNER' | 'TEACHER'>('LEARNER');
  errorMessage = signal<string | null>(null);
  showSuccessPopup = signal(false);

  constructor(
    private fb: FormBuilder,
    private authService: AuthService,
    private router: Router
  ) {
    this.registerForm = this.fb.group({
      fullName: ['', [Validators.required, Validators.minLength(3)]],
      email: ['', [Validators.required, Validators.email]],
      password: ['', [Validators.required, Validators.minLength(6)]],
      confirmPassword: ['', [Validators.required]]
    }, { validators: this.passwordMatchValidator });
  }

  passwordMatchValidator(form: FormGroup) {
    const password = form.get('password');
    const confirmPassword = form.get('confirmPassword');
    if (password && confirmPassword && password.value !== confirmPassword.value) {
      confirmPassword.setErrors({ passwordMismatch: true });
      return { passwordMismatch: true };
    }
    return null;
  }

  onSubmit(): void {
    if (this.registerForm.valid) {
      this.isLoading.set(true);
      this.errorMessage.set(null);

      const { fullName, email, password } = this.registerForm.value;
      const role = this.selectedRole();

      this.authService.register(fullName, email, password, role).subscribe({
        next: (response) => {
          this.isLoading.set(false);
          // Afficher le popup de succès
          this.showSuccessPopup.set(true);
          
          // Rediriger vers la page de connexion après 2 secondes
          setTimeout(() => {
            this.showSuccessPopup.set(false);
            this.router.navigate(['/login']);
          }, 2000);
        },
        error: (error) => {
          this.errorMessage.set(error.error?.message || 'Erreur lors de l\'inscription');
          this.isLoading.set(false);
        }
      });
    }
  }

  navigateToLogin(): void {
    this.router.navigate(['/login']);
  }

  closeSuccessPopup(): void {
    this.showSuccessPopup.set(false);
    this.router.navigate(['/login']);
  }
}







