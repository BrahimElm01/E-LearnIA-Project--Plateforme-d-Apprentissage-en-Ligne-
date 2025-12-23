import { Component, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, FormGroup, Validators, ReactiveFormsModule, FormArray } from '@angular/forms';
import { ActivatedRoute, Router, RouterModule } from '@angular/router';
import { CourseService } from '../../../services/course.service';
import { FileUploadService } from '../../../services/file-upload.service';
import { QuizService } from '../../../services/quiz.service';
import { TeacherCourse } from '../../../models/course.model';
import { Lesson } from '../../../models/lesson.model';
import { Quiz } from '../../../models/quiz.model';

@Component({
  selector: 'app-edit-course',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, RouterModule],
  templateUrl: './edit-course.component.html',
  styleUrl: './edit-course.component.css'
})
export class EditCourseComponent implements OnInit {
  courseForm: FormGroup;
  lessonForm: FormGroup;
  isSubmitting = signal(false);
  isLoading = signal(false);
  isLoadingLessons = signal(false);
  selectedFile: File | null = null;
  imagePreview = signal<string | null>(null);
  currentImageUrl = signal<string | null>(null);
  courseId = signal<number | null>(null);
  errorMessage = signal<string | null>(null);
  lessons = signal<Lesson[]>([]);
  showLessonForm = signal(false);
  editingLessonId = signal<number | null>(null);
  videoSourceType = signal<'none' | 'youtube' | 'upload'>('none');
  selectedVideoFile: File | null = null;
  isUploadingVideo = signal(false);
  showQuizModal = signal(false);
  currentLessonId = signal<number | null>(null);
  availableQuizzes = signal<Quiz[]>([]);
  isLoadingQuizzes = signal(false);
  lessonQuizzes = signal<Map<number, Quiz | null>>(new Map());

  constructor(
    private fb: FormBuilder,
    private courseService: CourseService,
    private fileUploadService: FileUploadService,
    private quizService: QuizService,
    private route: ActivatedRoute,
    private router: Router
  ) {
    this.courseForm = this.fb.group({
      title: ['', [Validators.required, Validators.minLength(3)]],
      description: ['', [Validators.required, Validators.minLength(10)]],
      published: [false],
      imageUrl: ['']
    });

    this.lessonForm = this.fb.group({
      title: ['', [Validators.required, Validators.minLength(3)]],
      description: [''],
      videoUrl: [''],
      duration: [0, [Validators.min(0)]],
      orderIndex: [1, [Validators.required, Validators.min(1)]]
    });
  }

  ngOnInit(): void {
    const id = Number(this.route.snapshot.paramMap.get('id'));
    if (isNaN(id)) {
      this.router.navigate(['/teacher/courses']);
      return;
    }
    this.courseId.set(id);
    this.loadCourse();
  }

  loadCourse(): void {
    this.isLoading.set(true);
    this.errorMessage.set(null);
    
    this.courseService.getTeacherCourseById(this.courseId()!).subscribe({
      next: (course) => {
        console.log('Course loaded:', course);
        this.courseForm.patchValue({
          title: course.title,
          description: course.description,
          published: course.published || false
        });
        
        if (course.imageUrl) {
          // Normaliser l'URL pour remplacer l'ancienne IP par localhost si nécessaire
          const normalizedUrl = this.normalizeImageUrl(course.imageUrl);
          this.currentImageUrl.set(normalizedUrl);
          this.imagePreview.set(normalizedUrl);
        }
        
        this.isLoading.set(false);
        this.loadLessons();
        this.loadAvailableQuizzes();
      },
      error: (error: any) => {
        console.error('Error loading course', error);
        this.errorMessage.set('Erreur lors du chargement du cours');
        this.isLoading.set(false);
        setTimeout(() => {
          this.router.navigate(['/teacher/courses']);
        }, 2000);
      }
    });
  }

  onFileSelected(event: any): void {
    const file = event.target.files[0];
    if (file) {
      this.selectedFile = file;
      const reader = new FileReader();
      reader.onload = () => {
        this.imagePreview.set(reader.result as string);
      };
      reader.readAsDataURL(file);
      this.currentImageUrl.set(null); // Réinitialiser l'URL actuelle si nouvelle image sélectionnée
    }
  }

  removeImage(): void {
    this.selectedFile = null;
    this.imagePreview.set(null);
    this.currentImageUrl.set(null);
    // Réinitialiser l'input file
    const fileInput = document.getElementById('image') as HTMLInputElement;
    if (fileInput) {
      fileInput.value = '';
    }
  }

  onImageError(event: Event): void {
    console.error('Erreur lors du chargement de l\'image:', event);
    const img = event.target as HTMLImageElement;
    // Essayer de normaliser l'URL si ce n'est pas déjà fait
    const currentSrc = img.src;
    const normalizedSrc = this.normalizeImageUrl(currentSrc);
    if (normalizedSrc !== currentSrc) {
      img.src = normalizedSrc;
    } else {
      // Si l'image ne se charge toujours pas, afficher un placeholder
      console.warn('Impossible de charger l\'image:', currentSrc);
    }
  }

  onImageLoad(event: Event): void {
    console.log('Image chargée avec succès');
  }

  onSubmit(): void {
    if (this.courseForm.valid && this.courseId()) {
      this.isSubmitting.set(true);
      
      if (this.selectedFile) {
        this.fileUploadService.uploadImage(this.selectedFile).subscribe({
          next: (response) => {
            this.updateCourse(response.url);
          },
          error: (error: any) => {
            console.error('Error uploading image', error);
            this.updateCourse();
          }
        });
      } else {
        this.updateCourse();
      }
    }
  }

  loadLessons(): void {
    if (!this.courseId()) return;
    
    this.isLoadingLessons.set(true);
    this.courseService.getCourseLessonsForTeacher(this.courseId()!).subscribe({
      next: (lessons) => {
        console.log('Lessons loaded:', lessons);
        this.lessons.set(lessons || []);
        // Charger les quizzes de chaque leçon
        lessons?.forEach(lesson => {
          this.loadLessonQuiz(lesson.id);
        });
        this.isLoadingLessons.set(false);
      },
      error: (error: any) => {
        console.error('Error loading lessons', error);
        this.lessons.set([]);
        this.isLoadingLessons.set(false);
      }
    });
  }

  openLessonForm(lesson?: Lesson): void {
    if (lesson) {
      this.editingLessonId.set(lesson.id);
      // Déterminer le type de source vidéo
      if (lesson.videoUrl && lesson.videoUrl.trim()) {
        const isYouTube = lesson.videoUrl.includes('youtube.com') || 
                         lesson.videoUrl.includes('youtu.be') ||
                         lesson.videoUrl.includes('youtube-nocookie.com');
        this.videoSourceType.set(isYouTube ? 'youtube' : 'upload');
      } else {
        this.videoSourceType.set('none');
      }
      this.lessonForm.patchValue({
        title: lesson.title,
        description: lesson.description || '',
        videoUrl: lesson.videoUrl || '',
        duration: lesson.duration || 0,
        orderIndex: lesson.orderIndex > 0 ? lesson.orderIndex : 1
      });
    } else {
      this.editingLessonId.set(null);
      this.videoSourceType.set('none');
      this.selectedVideoFile = null;
      const nextOrder = this.lessons().length > 0 
        ? Math.max(...this.lessons().map(l => l.orderIndex)) + 1 
        : 1;
      this.lessonForm.reset({
        title: '',
        description: '',
        videoUrl: '',
        duration: 0,
        orderIndex: nextOrder
      });
    }
    this.showLessonForm.set(true);
  }

  closeLessonForm(): void {
    this.showLessonForm.set(false);
    this.editingLessonId.set(null);
    this.videoSourceType.set('none');
    this.selectedVideoFile = null;
    this.lessonForm.reset();
  }

  onVideoFileSelected(event: any): void {
    const file = event.target.files[0];
    if (file) {
      // Vérifier que c'est une vidéo
      if (!file.type.startsWith('video/')) {
        alert('Veuillez sélectionner un fichier vidéo valide');
        const fileInput = document.getElementById('lesson-video-file') as HTMLInputElement;
        if (fileInput) {
          fileInput.value = '';
        }
        return;
      }
      
      // Vérifier la taille du fichier (max 500 MB)
      const maxSize = 500 * 1024 * 1024; // 500 MB en bytes
      if (file.size > maxSize) {
        alert(`Le fichier est trop volumineux. Taille maximale autorisée: 500 MB. Taille du fichier: ${(file.size / 1024 / 1024).toFixed(2)} MB`);
        const fileInput = document.getElementById('lesson-video-file') as HTMLInputElement;
        if (fileInput) {
          fileInput.value = '';
        }
        return;
      }
      
      this.selectedVideoFile = file;
      // Réinitialiser l'URL YouTube si un fichier est sélectionné
      this.lessonForm.patchValue({ videoUrl: '' });
    }
  }

  onVideoSourceTypeChange(type: 'none' | 'youtube' | 'upload'): void {
    this.videoSourceType.set(type);
    if (type === 'youtube') {
      this.selectedVideoFile = null;
      // Réinitialiser l'input file
      const fileInput = document.getElementById('lesson-video-file') as HTMLInputElement;
      if (fileInput) {
        fileInput.value = '';
      }
    } else if (type === 'upload') {
      this.lessonForm.patchValue({ videoUrl: '' });
    } else {
      // Type 'none' - réinitialiser tout
      this.selectedVideoFile = null;
      this.lessonForm.patchValue({ videoUrl: '' });
      const fileInput = document.getElementById('lesson-video-file') as HTMLInputElement;
      if (fileInput) {
        fileInput.value = '';
      }
    }
  }

  saveLesson(): void {
    if (!this.lessonForm.get('title')?.valid || !this.courseId()) {
      alert('Veuillez remplir tous les champs requis');
      return;
    }

    const lessonData = this.lessonForm.value;
    let videoUrl: string | null = null;

    // Valider et traiter la vidéo selon le type de source
    if (this.videoSourceType() === 'youtube') {
      const videoUrlControl = this.lessonForm.get('videoUrl');
      if (videoUrlControl?.value && videoUrlControl.value.trim()) {
        // Valider l'URL YouTube seulement si elle est fournie
        if (!videoUrlControl.value.match(/^(https?:\/\/)?(www\.)?(youtube\.com|youtu\.be)\/.+/)) {
          alert('Veuillez entrer une URL YouTube valide ou laisser vide pour une leçon sans vidéo');
          return;
        }
        videoUrl = videoUrlControl.value.trim();
      }
      // Si pas d'URL YouTube, videoUrl reste null
    } else if (this.videoSourceType() === 'upload') {
      if (this.selectedVideoFile) {
        // Uploader la vidéo
        this.isUploadingVideo.set(true);
        this.fileUploadService.uploadVideo(this.selectedVideoFile).subscribe({
          next: (response) => {
            this.isUploadingVideo.set(false);
            videoUrl = response.url;
            const lesson: Partial<Lesson> = {
              title: lessonData.title,
              description: lessonData.description || undefined,
              videoUrl: videoUrl,
              duration: lessonData.duration || undefined,
              orderIndex: lessonData.orderIndex || this.lessons().length + 1
            };
            this.saveLessonToBackend(lesson);
          },
          error: (error: any) => {
            console.error('Error uploading video', error);
            this.isUploadingVideo.set(false);
            
            let errorMessage = 'Erreur lors de l\'upload de la vidéo';
            
            if (error.status === 413) {
              errorMessage = 'Le fichier est trop volumineux. Taille maximale: 500 MB';
            } else if (error.status === 401 || error.status === 403) {
              errorMessage = 'Erreur d\'authentification. Veuillez vous reconnecter';
            } else if (error.status === 0) {
              errorMessage = 'Erreur de connexion au serveur. Vérifiez votre connexion internet';
            } else if (error.error?.message) {
              errorMessage = error.error.message;
            } else if (error.message) {
              errorMessage = error.message;
            }
            
            alert(errorMessage);
          }
        });
        return; // Attendre la fin de l'upload
      }
      // Si pas de fichier sélectionné, on peut créer une leçon sans vidéo
    }

    // Créer la leçon (avec ou sans vidéo)
    // S'assurer que orderIndex est toujours défini
    const orderIndex = lessonData.orderIndex && lessonData.orderIndex > 0 
      ? lessonData.orderIndex 
      : (this.lessons().length > 0 
          ? Math.max(...this.lessons().map(l => l.orderIndex)) + 1 
          : 1);
    
    const lesson: Partial<Lesson> = {
      title: lessonData.title,
      description: lessonData.description || undefined,
      videoUrl: videoUrl || null, // null si pas de vidéo (au lieu de chaîne vide)
      duration: lessonData.duration || undefined,
      orderIndex: orderIndex
    };
    
    this.saveLessonToBackend(lesson);
  }

  private saveLessonToBackend(lesson: Partial<Lesson>): void {
    // S'assurer que tous les champs requis sont présents
    if (!lesson.title || !lesson.title.trim()) {
      alert('Le titre de la leçon est requis');
      return;
    }
    
    if (lesson.orderIndex === undefined || lesson.orderIndex === null) {
      alert('L\'ordre de la leçon est requis');
      return;
    }

    // Préparer l'objet pour l'API
    const lessonPayload: any = {
      title: lesson.title.trim(),
      description: lesson.description || null,
      videoUrl: lesson.videoUrl || null,
      duration: lesson.duration || null,
      orderIndex: lesson.orderIndex
    };

    console.log('Saving lesson:', lessonPayload);

    if (this.editingLessonId()) {
      // Modifier une leçon existante
      this.courseService.updateLesson(this.courseId()!, this.editingLessonId()!, lessonPayload).subscribe({
        next: () => {
          this.loadLessons();
          this.closeLessonForm();
        },
        error: (error: any) => {
          console.error('Error updating lesson', error);
          let errorMessage = 'Erreur lors de la mise à jour de la leçon';
          if (error.error?.message) {
            errorMessage += ': ' + error.error.message;
          } else if (error.error?.error) {
            errorMessage += ': ' + error.error.error;
          } else if (error.message) {
            errorMessage += ': ' + error.message;
          }
          alert(errorMessage);
        }
      });
    } else {
      this.courseService.addLesson(this.courseId()!, lessonPayload).subscribe({
        next: () => {
          this.loadLessons();
          this.closeLessonForm();
        },
        error: (error: any) => {
          console.error('Error adding lesson', error);
          let errorMessage = 'Erreur lors de l\'ajout de la leçon';
          if (error.error?.message) {
            errorMessage += ': ' + error.error.message;
          } else if (error.error?.error) {
            errorMessage += ': ' + error.error.error;
          } else if (error.message) {
            errorMessage += ': ' + error.message;
          }
          alert(errorMessage);
        }
      });
    }
  }

  deleteLesson(lessonId: number): void {
    if (confirm('Êtes-vous sûr de vouloir supprimer cette leçon ?')) {
      this.courseService.deleteLesson(this.courseId()!, lessonId).subscribe({
        next: () => {
          this.loadLessons();
        },
        error: (error: any) => {
          console.error('Error deleting lesson', error);
          alert('Erreur lors de la suppression de la leçon');
        }
      });
    }
  }

  convertToEmbedUrl(url: string): string {
    // Convertir l'URL YouTube en URL d'embed
    const regExp = /^.*(youtu.be\/|v\/|u\/\w\/|embed\/|watch\?v=|&v=)([^#&?]*).*/;
    const match = url.match(regExp);
    const videoId = (match && match[2].length === 11) ? match[2] : null;
    if (videoId) {
      return `https://www.youtube.com/embed/${videoId}`;
    }
    return url;
  }

  openQuizModal(lessonId: number): void {
    this.currentLessonId.set(lessonId);
    this.loadLessonQuiz(lessonId);
    this.showQuizModal.set(true);
  }

  closeQuizModal(): void {
    this.showQuizModal.set(false);
    this.currentLessonId.set(null);
  }

  loadAvailableQuizzes(): void {
    this.isLoadingQuizzes.set(true);
    this.quizService.getTeacherQuizzes().subscribe({
      next: (quizzes) => {
        this.availableQuizzes.set(quizzes);
        this.isLoadingQuizzes.set(false);
      },
      error: (error) => {
        console.error('Error loading quizzes', error);
        this.isLoadingQuizzes.set(false);
      }
    });
  }

  loadLessonQuiz(lessonId: number): void {
    if (!this.courseId()) return;
    this.courseService.getLessonQuizForTeacher(this.courseId()!, lessonId).subscribe({
      next: (quiz) => {
        const map = new Map(this.lessonQuizzes());
        map.set(lessonId, quiz);
        this.lessonQuizzes.set(map);
      },
      error: (error) => {
        if (error.status !== 204) { // 204 = No Content (pas de quiz)
          console.error('Error loading lesson quiz', error);
        }
        const map = new Map(this.lessonQuizzes());
        map.set(lessonId, null);
        this.lessonQuizzes.set(map);
      }
    });
  }

  assignExistingQuiz(quizId: number): void {
    const lessonId = this.currentLessonId();
    if (!lessonId || !this.courseId()) return;

    this.courseService.assignQuizToLesson(this.courseId()!, lessonId, quizId).subscribe({
      next: () => {
        alert('Quiz associé à la leçon avec succès !');
        this.loadLessonQuiz(lessonId);
        this.loadLessons();
      },
      error: (error) => {
        console.error('Error assigning quiz', error);
        alert('Erreur lors de l\'association du quiz');
      }
    });
  }

  removeQuizFromLesson(): void {
    const lessonId = this.currentLessonId();
    if (!lessonId || !this.courseId()) return;

    if (confirm('Êtes-vous sûr de vouloir retirer le quiz de cette leçon ?')) {
      this.courseService.removeQuizFromLesson(this.courseId()!, lessonId).subscribe({
        next: () => {
          alert('Quiz retiré de la leçon avec succès !');
          this.loadLessonQuiz(lessonId);
          this.loadLessons();
        },
        error: (error) => {
          console.error('Error removing quiz', error);
          alert('Erreur lors du retrait du quiz');
        }
      });
    }
  }

  createNewQuizForLesson(): void {
    const lessonId = this.currentLessonId();
    if (!lessonId || !this.courseId()) return;

    // Rediriger vers la page de génération de quiz avec le lessonId et courseId en paramètres
    this.router.navigate(['/teacher/generate-quiz'], {
      queryParams: { lessonId, courseId: this.courseId() }
    });
  }

  navigateBack(): void {
    this.router.navigate(['/teacher/courses']);
  }

  getDescriptionPreview(description: string): string {
    if (!description) return '';
    // Limiter à 120 caractères maximum
    const maxLength = 120;
    if (description.length <= maxLength) {
      return description;
    }
    // Tronquer et ajouter des points de suspension
    return description.substring(0, maxLength).trim() + '...';
  }

  getLessonQuiz(lessonId: number): Quiz | null {
    return this.lessonQuizzes().get(lessonId) || null;
  }

  /**
   * Normalise l'URL de l'image en utilisant le service
   */
  private normalizeImageUrl(url: string): string {
    const normalized = this.fileUploadService.normalizeImageUrl(url);
    return normalized || url;
  }

  private updateCourse(imageUrl?: string): void {
    const formValue = this.courseForm.value;
    // Si une nouvelle image a été uploadée, utiliser son URL, sinon garder l'image actuelle ou undefined
    const imageToUse = imageUrl !== undefined ? imageUrl : (this.currentImageUrl() || undefined);
    
    this.courseService.updateCourse(
      this.courseId()!, 
      formValue.title, 
      formValue.description, 
      imageToUse,
      formValue.published
    ).subscribe({
      next: (updatedCourse) => {
        // Mettre à jour les signaux d'image avec la nouvelle URL (soit celle uploadée, soit celle retournée par le backend)
        const newImageUrl = imageUrl || updatedCourse.imageUrl || null;
        const normalizedUrl = newImageUrl ? this.normalizeImageUrl(newImageUrl) : null;
        this.currentImageUrl.set(normalizedUrl);
        this.imagePreview.set(normalizedUrl);
        
        // Réinitialiser le fichier sélectionné et l'input file
        this.selectedFile = null;
        const fileInput = document.getElementById('image') as HTMLInputElement;
        if (fileInput) {
          fileInput.value = '';
        }
        
        // Mettre à jour le formulaire avec les données du cours mis à jour
        this.courseForm.patchValue({
          title: updatedCourse.title,
          description: updatedCourse.description,
          published: updatedCourse.published || false
        });
        
        this.isSubmitting.set(false);
        alert('Cours mis à jour avec succès !');
      },
      error: (error: any) => {
        console.error('Error updating course', error);
        this.errorMessage.set(error.error?.message || 'Erreur lors de la mise à jour du cours');
        this.isSubmitting.set(false);
        alert('Erreur lors de la mise à jour du cours. Vérifiez la console pour plus de détails.');
      }
    });
  }
}

