import { Component, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router, RouterModule } from '@angular/router';
import { FormBuilder, FormGroup, Validators, ReactiveFormsModule } from '@angular/forms';
import { AuthService } from '../../../services/auth.service';
import { User } from '../../../models/user.model';

@Component({
  selector: 'app-profile',
  standalone: true,
  imports: [CommonModule, RouterModule, ReactiveFormsModule],
  templateUrl: './profile.component.html',
  styleUrl: './profile.component.css'
})
export class ProfileComponent implements OnInit {
  user = signal<User | null>(null);
  isEditing = signal(false);
  profileForm: FormGroup;
  isSaving = signal(false);
  errorMessage = signal<string | null>(null);
  successMessage = signal<string | null>(null);

  constructor(
    private authService: AuthService,
    private router: Router,
    private fb: FormBuilder
  ) {
    this.profileForm = this.fb.group({
      fullName: ['', [Validators.required, Validators.minLength(3)]],
      email: ['', [Validators.required, Validators.email]],
      biography: ['']
    });
  }

  ngOnInit(): void {
    const currentUser = this.authService.getCurrentUser();
    
    // Récupérer la biographie depuis localStorage si elle existe
    if (currentUser) {
      try {
        const storedUserStr = localStorage.getItem('auth_user');
        if (storedUserStr) {
          const storedUser = JSON.parse(storedUserStr);
          if (storedUser.biography) {
            currentUser.biography = storedUser.biography;
          }
        }
      } catch (e) {
        console.error('Error loading biography from storage', e);
      }
    }
    
    this.user.set(currentUser);
    
    if (currentUser) {
      this.profileForm.patchValue({
        fullName: currentUser.fullName || '',
        email: currentUser.email || '',
        biography: currentUser.biography || ''
      });
    }
  }

  startEditing(): void {
    this.isEditing.set(true);
    this.errorMessage.set(null);
    this.successMessage.set(null);
  }

  cancelEditing(): void {
    const currentUser = this.user();
    if (currentUser) {
      this.profileForm.patchValue({
        fullName: currentUser.fullName || '',
        email: currentUser.email || '',
        biography: currentUser.biography || ''
      });
    }
    this.isEditing.set(false);
    this.errorMessage.set(null);
    this.successMessage.set(null);
  }

  saveProfile(): void {
    if (this.profileForm.invalid) {
      this.profileForm.markAllAsTouched();
      return;
    }

    this.isSaving.set(true);
    this.errorMessage.set(null);
    this.successMessage.set(null);

    const formValue = this.profileForm.value;
    
    this.authService.updateProfile(formValue.fullName, formValue.email).subscribe({
      next: (updatedUser) => {
        // Le service auth préserve déjà la biographie, mais on la met à jour avec la nouvelle valeur
        const userWithBio = {
          ...updatedUser,
          biography: formValue.biography || updatedUser.biography
        };
        
        // Sauvegarder dans localStorage
        localStorage.setItem('auth_user', JSON.stringify(userWithBio));
        this.user.set(userWithBio);
        
        this.isEditing.set(false);
        this.isSaving.set(false);
        this.successMessage.set('Profil mis à jour avec succès !');
        
        // Masquer le message de succès après 3 secondes
        setTimeout(() => {
          this.successMessage.set(null);
        }, 3000);
      },
      error: (error: any) => {
        console.error('Error updating profile', error);
        let errorMsg = 'Erreur lors de la mise à jour du profil';
        if (error.status === 409) {
          errorMsg = 'Cet email est déjà utilisé par un autre compte';
        } else if (error.error?.message) {
          errorMsg = error.error.message;
        }
        this.errorMessage.set(errorMsg);
        this.isSaving.set(false);
      }
    });
  }

  logout(): void {
    if (confirm('Êtes-vous sûr de vouloir vous déconnecter ?')) {
      this.authService.logout();
      this.router.navigate(['/login']);
    }
  }

  getRoleDisplayName(role: string): string {
    const roleMap: { [key: string]: string } = {
      'ROLE_LEARNER': 'Étudiant',
      'ROLE_TEACHER': 'Professeur',
      'ROLE_ADMIN': 'Administrateur',
      'LEARNER': 'Étudiant',
      'TEACHER': 'Professeur',
      'ADMIN': 'Administrateur'
    };
    return roleMap[role] || role;
  }

  navigateBack(): void {
    this.router.navigate(['/student/home']);
  }
}







