import { Component, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, FormGroup, Validators, ReactiveFormsModule } from '@angular/forms';
import { Router, RouterModule } from '@angular/router';
import { AuthService } from '../../../services/auth.service';
import { User } from '../../../models/user.model';

@Component({
  selector: 'app-teacher-profile',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, RouterModule],
  templateUrl: './profile.component.html',
  styleUrl: './profile.component.css'
})
export class TeacherProfileComponent implements OnInit {
  profileForm: FormGroup;
  user = signal<User | null>(null);
  isEditing = signal(false);
  isSaving = signal(false);
  errorMessage = signal<string | null>(null);
  successMessage = signal<string | null>(null);

  constructor(
    private fb: FormBuilder,
    private authService: AuthService,
    private router: Router
  ) {
    this.profileForm = this.fb.group({
      fullName: ['', [Validators.required, Validators.minLength(2)]],
      email: ['', [Validators.required, Validators.email]]
    });
  }

  ngOnInit(): void {
    const currentUser = this.authService.getCurrentUser();
    if (currentUser) {
      this.user.set(currentUser);
      this.profileForm.patchValue({
        fullName: currentUser.fullName,
        email: currentUser.email
      });
    }
  }

  toggleEdit(): void {
    this.isEditing.set(!this.isEditing());
    this.errorMessage.set(null);
    this.successMessage.set(null);
    
    if (!this.isEditing()) {
      // Annuler les modifications
      const currentUser = this.user();
      if (currentUser) {
        this.profileForm.patchValue({
          fullName: currentUser.fullName,
          email: currentUser.email
        });
      }
    }
  }

  saveProfile(): void {
    if (this.profileForm.valid) {
      this.isSaving.set(true);
      this.errorMessage.set(null);
      this.successMessage.set(null);

      const { fullName, email } = this.profileForm.value;
      this.authService.updateProfile(fullName, email).subscribe({
        next: (updatedUser: User) => {
          this.user.set(updatedUser);
          this.isEditing.set(false);
          this.isSaving.set(false);
          this.successMessage.set('Profil mis à jour avec succès');
          setTimeout(() => this.successMessage.set(null), 3000);
        },
        error: (error: any) => {
          console.error('Error updating profile', error);
          this.errorMessage.set(error.error?.message || 'Erreur lors de la mise à jour du profil');
          this.isSaving.set(false);
        }
      });
    }
  }

  logout(): void {
    this.authService.logout();
    this.router.navigate(['/login']);
  }

  navigateToHome(): void {
    this.router.navigate(['/teacher/home']);
  }
}







