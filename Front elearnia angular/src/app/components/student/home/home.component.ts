import { Component, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router, RouterModule } from '@angular/router';
import { CourseService } from '../../../services/course.service';
import { AuthService } from '../../../services/auth.service';
import { StudentCourse } from '../../../models/course.model';
import { User } from '../../../models/user.model';
import { FeaturesCarouselComponent } from './features-carousel.component';

@Component({
  selector: 'app-home',
  standalone: true,
  imports: [CommonModule, RouterModule, FeaturesCarouselComponent],
  templateUrl: './home.component.html',
  styleUrl: './home.component.css'
})
export class HomeComponent implements OnInit {
  user: User | null = null;
  courses = signal<StudentCourse[]>([]);
  isLoading = signal(false);
  categories = signal<string[]>([]);
  globalProgress = signal<number>(0);

  constructor(
    private courseService: CourseService,
    private authService: AuthService,
    private router: Router
  ) {}

  ngOnInit(): void {
    this.user = this.authService.getCurrentUser();
    this.loadCourses();
    this.extractCategories();
  }

  loadCourses(): void {
    this.isLoading.set(true);
    this.courseService.getStudentCourses().subscribe({
      next: (courses: any) => {
        this.courses.set(courses);
        this.calculateGlobalProgress();
        this.extractCategories();
        this.isLoading.set(false);
      },
      error: (error: any) => {
        console.error('Error loading courses', error);
        this.isLoading.set(false);
      }
    });
  }

  calculateGlobalProgress(): void {
    const courses = this.courses();
    if (courses.length === 0) {
      this.globalProgress.set(0);
      return;
    }

    // Limiter chaque progression à 100% avant de calculer la moyenne
    const totalProgress = courses.reduce((sum, course) => {
      const limitedProgress = Math.min(100, Math.max(0, course.progress));
      return sum + limitedProgress;
    }, 0);
    const averageProgress = totalProgress / courses.length;
    this.globalProgress.set(Math.min(100, Math.round(averageProgress)));
  }

  extractCategories(): void {
    // Extraire les catégories depuis les cours avec une logique stricte
    const categoryCoursesMap = new Map<string, number>();
    const categoryMap = new Map<string, { keywords: string[], required?: string[] }>();
    
    // Définir les mots-clés pour chaque catégorie avec des mots-clés requis pour une correspondance forte
    categoryMap.set('Développement Mobile', {
      keywords: ['flutter', 'dart', 'react native', 'ionic', 'xamarin', 'mobile app', 'android', 'ios', 'swift', 'kotlin'],
      required: ['mobile', 'flutter', 'react native', 'ionic', 'xamarin', 'android', 'ios']
    });
    categoryMap.set('Backend', {
      keywords: ['spring', 'java', 'node.js', 'express', 'django', 'flask', 'php', 'backend', 'api', 'rest', 'graphql', 'server'],
      required: ['backend', 'api', 'server', 'spring', 'express', 'django', 'flask']
    });
    categoryMap.set('Frontend', {
      keywords: ['react', 'angular', 'vue', 'javascript', 'typescript', 'html', 'css', 'frontend', 'web development', 'jsx', 'tsx'],
      required: ['react', 'angular', 'vue', 'frontend', 'html', 'css', 'javascript']
    });
    categoryMap.set('Python', {
      keywords: ['python', 'django', 'flask', 'pandas', 'numpy', 'python programming'],
      required: ['python']
    });
    categoryMap.set('Base de données', {
      keywords: ['sql', 'mysql', 'postgresql', 'mongodb', 'database', 'oracle', 'nosql', 'db'],
      required: ['sql', 'database', 'mysql', 'postgresql', 'mongodb', 'oracle']
    });
    categoryMap.set('DevOps', {
      keywords: ['docker', 'kubernetes', 'ci/cd', 'jenkins', 'git', 'devops', 'deployment', 'ci cd', 'cicd'],
      required: ['docker', 'kubernetes', 'devops', 'ci/cd', 'jenkins']
    });
    categoryMap.set('Design', {
      keywords: ['ui', 'ux', 'design', 'figma', 'adobe', 'canva', 'graphic design', 'photoshop', 'illustrator', 'premiere', 'after effects'],
      required: ['design', 'ui', 'ux', 'figma', 'adobe', 'canva', 'photoshop', 'illustrator', 'premiere']
    });
    categoryMap.set('Cybersécurité', {
      keywords: ['security', 'cybersecurity', 'hacking', 'ethical hacking', 'sécurité', 'penetration testing', 'cyber'],
      required: ['security', 'cybersecurity', 'hacking', 'sécurité', 'cyber']
    });
    categoryMap.set('Cloud', {
      keywords: ['aws', 'azure', 'gcp', 'cloud', 'serverless', 'amazon web services', 'google cloud', 'microsoft azure'],
      required: ['aws', 'azure', 'gcp', 'cloud', 'serverless']
    });
    categoryMap.set('Data Science', {
      keywords: ['data science', 'machine learning', 'ai', 'artificial intelligence', 'deep learning', 'tensorflow', 'data analysis', 'neural network', 'pandas', 'numpy', 'scikit-learn', 'keras', 'pytorch'],
      required: ['data science', 'machine learning', 'ai', 'artificial intelligence', 'data analysis', 'deep learning', 'tensorflow']
    });

    this.courses().forEach(course => {
      const title = course.title.toLowerCase();
      const description = (course.description || '').toLowerCase();
      const searchText = title + ' ' + description;

      // Parcourir toutes les catégories et vérifier la correspondance forte
      categoryMap.forEach((config, category) => {
        const { keywords, required } = config;
        
        // Pour Data Science, exclure les cours qui sont clairement dans d'autres catégories
        if (category === 'Data Science') {
          const excludedKeywords = ['html', 'css', 'javascript', 'react', 'angular', 'vue', 'frontend', 'web development', 'spring', 'java', 'backend', 'flutter', 'mobile'];
          const hasExcluded = excludedKeywords.some(k => title.includes(k) || description.includes(k));
          if (hasExcluded) {
            return; // Skip this category for this course
          }
        }
        
        // Vérifier qu'au moins un mot-clé requis est présent (correspondance forte)
        const hasRequired = required ? required.some(keyword => {
          // Pour les mots-clés composés, vérifier qu'ils sont présents comme phrases complètes
          if (keyword.includes(' ')) {
            return searchText.includes(keyword);
          }
          // Pour les mots-clés courts, vérifier qu'ils ne sont pas dans d'autres mots
          const regex = new RegExp(`\\b${keyword}\\b`, 'i');
          return regex.test(searchText);
        }) : true;
        
        if (!hasRequired) {
          return; // Skip this category for this course
        }
        
        // Compter le nombre de mots-clés correspondants (avec vérification de mots complets)
        const matchCount = keywords.filter(keyword => {
          if (keyword.includes(' ')) {
            return searchText.includes(keyword);
          }
          // Utiliser des limites de mots pour éviter les correspondances partielles
          const regex = new RegExp(`\\b${keyword}\\b`, 'i');
          return regex.test(searchText);
        }).length;
        
        // Un cours appartient à une catégorie seulement si :
        // 1. Il a au moins un mot-clé requis (si défini)
        // 2. Il a au moins 2 correspondances de mots-clés OU un mot-clé très spécifique (longueur > 8)
        if (matchCount >= 2 || keywords.some(k => {
          if (k.includes(' ')) {
            return searchText.includes(k);
          }
          const regex = new RegExp(`\\b${k}\\b`, 'i');
          return regex.test(searchText) && k.length > 8;
        })) {
          categoryCoursesMap.set(category, (categoryCoursesMap.get(category) || 0) + 1);
        }
      });
    });

    // Ne garder que les catégories qui ont au moins un cours
    const validCategories = Array.from(categoryCoursesMap.keys()).sort();
    this.categories.set(validCategories);
  }

  navigateToCourse(courseId: number): void {
    this.router.navigate(['/student/course', courseId]);
  }

  navigateToCategory(category: string): void {
    // Implémenter la navigation vers les cours par catégorie
    this.router.navigate(['/student/courses'], { queryParams: { category } });
  }

  navigateToProfile(): void {
    this.router.navigate(['/student/profile']);
  }

  navigateToMyCourses(): void {
    this.router.navigate(['/student/courses']);
  }

  navigateToQuizzes(): void {
    this.router.navigate(['/student/quizzes']);
  }

  navigateToAnalytics(): void {
    this.router.navigate(['/student/analytics']);
  }

  logout(): void {
    this.authService.logout();
    this.router.navigate(['/login']);
  }

  // Getters pour éviter les arrow functions dans les templates
  get completedCoursesCount(): number {
    // Un cours est complété s'il a 100% de progression
    return this.courses().filter((c: StudentCourse) => {
      const progress = c.progress || 0;
      return progress >= 100;
    }).length;
  }

  get inProgressCoursesCount(): number {
    return this.courses().filter((c: StudentCourse) => {
      const progress = c.progress || 0;
      // Un cours est en cours s'il a une progression entre 1% et 99%
      // On ignore le statut completed car il peut être incorrect
      return progress >= 1 && progress <= 99;
    }).length;
  }

  get inProgressCourses(): StudentCourse[] {
    // Filtrer les cours qui sont en cours (progress entre 1% et 99%)
    // On se base uniquement sur la progression, pas sur le statut completed
    return this.courses().filter((c: StudentCourse) => {
      const progress = c.progress || 0;
      return progress >= 1 && progress <= 99;
    });
  }

  get hasInProgressCourses(): boolean {
    const inProgress = this.inProgressCourses;
    return inProgress.length > 0;
  }

  getCategoryIcon(category: string): string {
    const iconMap: { [key: string]: string } = {
      'Développement Mobile': '📱',
      'Backend': '⚙️',
      'Frontend': '💻',
      'Python': '🐍',
      'Base de données': '🗄️',
      'DevOps': '🔧',
      'Design': '🎨',
      'Cybersécurité': '🔒',
      'Cloud': '☁️',
      'Data Science': '📈'
    };
    return iconMap[category] || '📁';
  }

  getCategoryCourseCount(category: string): number {
    const categoryMap: { [key: string]: { keywords: string[], required?: string[] } } = {
      'Développement Mobile': {
        keywords: ['flutter', 'dart', 'react native', 'ionic', 'xamarin', 'mobile app', 'android', 'ios', 'swift', 'kotlin'],
        required: ['mobile', 'flutter', 'react native', 'ionic', 'xamarin', 'android', 'ios']
      },
      'Backend': {
        keywords: ['spring', 'java', 'node.js', 'express', 'django', 'flask', 'php', 'backend', 'api', 'rest', 'graphql', 'server'],
        required: ['backend', 'api', 'server', 'spring', 'express', 'django', 'flask']
      },
      'Frontend': {
        keywords: ['react', 'angular', 'vue', 'javascript', 'typescript', 'html', 'css', 'frontend', 'web development', 'jsx', 'tsx'],
        required: ['react', 'angular', 'vue', 'frontend', 'html', 'css', 'javascript']
      },
      'Python': {
        keywords: ['python', 'django', 'flask', 'pandas', 'numpy', 'python programming'],
        required: ['python']
      },
      'Base de données': {
        keywords: ['sql', 'mysql', 'postgresql', 'mongodb', 'database', 'oracle', 'nosql', 'db'],
        required: ['sql', 'database', 'mysql', 'postgresql', 'mongodb', 'oracle']
      },
      'DevOps': {
        keywords: ['docker', 'kubernetes', 'ci/cd', 'jenkins', 'git', 'devops', 'deployment', 'ci cd', 'cicd'],
        required: ['docker', 'kubernetes', 'devops', 'ci/cd', 'jenkins']
      },
      'Design': {
        keywords: ['ui', 'ux', 'design', 'figma', 'adobe', 'canva', 'graphic design', 'photoshop', 'illustrator', 'premiere', 'after effects'],
        required: ['design', 'ui', 'ux', 'figma', 'adobe', 'canva', 'photoshop', 'illustrator', 'premiere']
      },
      'Cybersécurité': {
        keywords: ['security', 'cybersecurity', 'hacking', 'ethical hacking', 'sécurité', 'penetration testing', 'cyber'],
        required: ['security', 'cybersecurity', 'hacking', 'sécurité', 'cyber']
      },
      'Cloud': {
        keywords: ['aws', 'azure', 'gcp', 'cloud', 'serverless', 'amazon web services', 'google cloud', 'microsoft azure'],
        required: ['aws', 'azure', 'gcp', 'cloud', 'serverless']
      },
      'Data Science': {
        keywords: ['data science', 'machine learning', 'ai', 'artificial intelligence', 'deep learning', 'tensorflow', 'data analysis', 'neural network', 'pandas', 'numpy', 'scikit-learn', 'keras', 'pytorch'],
        required: ['data science', 'machine learning', 'ai', 'artificial intelligence', 'data analysis', 'deep learning', 'tensorflow']
      }
    };

    const config = categoryMap[category];
    if (!config) return 0;

    const { keywords, required } = config;
    return this.courses().filter(course => {
      const title = course.title.toLowerCase();
      const description = (course.description || '').toLowerCase();
      const searchText = title + ' ' + description;
      
      // Pour Data Science, exclure les cours qui sont clairement dans d'autres catégories
      if (category === 'Data Science') {
        const excludedKeywords = ['html', 'css', 'javascript', 'react', 'angular', 'vue', 'frontend', 'web development', 'spring', 'java', 'backend', 'flutter', 'mobile'];
        const hasExcluded = excludedKeywords.some(k => title.includes(k) || description.includes(k));
        if (hasExcluded) {
          return false;
        }
      }
      
      // Vérifier qu'au moins un mot-clé requis est présent (correspondance forte)
      const hasRequired = required ? required.some(keyword => {
        // Pour les mots-clés composés, vérifier qu'ils sont présents comme phrases complètes
        if (keyword.includes(' ')) {
          return searchText.includes(keyword);
        }
        // Pour les mots-clés courts, vérifier qu'ils ne sont pas dans d'autres mots
        const regex = new RegExp(`\\b${keyword}\\b`, 'i');
        return regex.test(searchText);
      }) : true;
      
      if (!hasRequired) {
        return false;
      }
      
      // Compter le nombre de mots-clés correspondants (avec vérification de mots complets)
      const matchCount = keywords.filter(keyword => {
        if (keyword.includes(' ')) {
          return searchText.includes(keyword);
        }
        // Utiliser des limites de mots pour éviter les correspondances partielles
        const regex = new RegExp(`\\b${keyword}\\b`, 'i');
        return regex.test(searchText);
      }).length;
      
      // Un cours appartient à une catégorie seulement s'il a une correspondance forte :
      // 1. Il a au moins un mot-clé requis (si défini)
      // 2. Il a au moins 2 correspondances de mots-clés OU un mot-clé très spécifique (longueur > 8)
      return matchCount >= 2 || keywords.some(k => {
        if (k.includes(' ')) {
          return searchText.includes(k);
        }
        const regex = new RegExp(`\\b${k}\\b`, 'i');
        return regex.test(searchText) && k.length > 8;
      });
    }).length;
  }

  // Limiter la progression à 100% maximum
  getLimitedProgress(progress: number): number {
    return Math.min(100, Math.max(0, progress));
  }
}

