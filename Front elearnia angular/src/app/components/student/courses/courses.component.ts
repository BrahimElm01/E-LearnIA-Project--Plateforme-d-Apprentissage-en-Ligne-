import { Component, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router, RouterModule, ActivatedRoute } from '@angular/router';
import { CourseService } from '../../../services/course.service';
import { StudentCourse } from '../../../models/course.model';

@Component({
  selector: 'app-courses',
  standalone: true,
  imports: [CommonModule, RouterModule, FormsModule],
  templateUrl: './courses.component.html',
  styleUrl: './courses.component.css'
})
export class CoursesComponent implements OnInit {
  courses = signal<StudentCourse[]>([]);
  filteredCourses = signal<StudentCourse[]>([]);
  isLoading = signal(false);
  category = signal<string | null>(null);
  filterType = signal<'all' | 'completed' | 'in-progress'>('all');
  searchQuery = signal<string>('');

  constructor(
    private courseService: CourseService,
    private router: Router,
    private route: ActivatedRoute
  ) {}

  ngOnInit(): void {
    this.route.queryParams.subscribe(params => {
      this.category.set(params['category'] || null);
      this.loadCourses();
    });
  }

  loadCourses(): void {
    this.isLoading.set(true);
    this.courseService.getStudentCourses().subscribe({
      next: (courses) => {
        let filtered = courses;
        if (this.category()) {
          filtered = this.filterByCategory(courses, this.category()!);
        }
        this.courses.set(filtered);
        this.applyFilters();
        this.isLoading.set(false);
      },
      error: (error) => {
        console.error('Error loading courses', error);
        this.isLoading.set(false);
      }
    });
  }

  filterByCategory(courses: StudentCourse[], category: string): StudentCourse[] {
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
    if (!config) {
      // Si la catégorie n'est pas reconnue, chercher dans le titre (fallback)
      return courses.filter(c => 
        c.title.toLowerCase().includes(category.toLowerCase())
      );
    }

    const { keywords, required } = config;
    return courses.filter(course => {
      const title = course.title.toLowerCase();
      const description = (course.description || '').toLowerCase();
      const searchText = title + ' ' + description;
      
      // Pour Data Science, être encore plus strict - éviter les faux positifs
      if (category === 'Data Science') {
        // Exclure les cours qui sont clairement dans d'autres catégories
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
    });
  }

  applyFilters(): void {
    let filtered = [...this.courses()];

    // Filtre par type
    if (this.filterType() === 'completed') {
      filtered = filtered.filter(c => {
        const progress = c.progress || 0;
        return progress >= 100;
      });
    } else if (this.filterType() === 'in-progress') {
      filtered = filtered.filter(c => {
        const progress = c.progress || 0;
        return progress > 0 && progress < 100;
      });
    }

    // Filtre par recherche
    if (this.searchQuery().trim()) {
      const query = this.searchQuery().toLowerCase();
      filtered = filtered.filter(c => 
        c.title.toLowerCase().includes(query) ||
        c.description?.toLowerCase().includes(query) ||
        c.teacherName.toLowerCase().includes(query)
      );
    }

    this.filteredCourses.set(filtered);
  }

  onFilterChange(filter: 'all' | 'completed' | 'in-progress'): void {
    this.filterType.set(filter);
    this.applyFilters();
  }

  onSearchChange(): void {
    this.applyFilters();
  }

  navigateToCourse(courseId: number): void {
    this.router.navigate(['/student/course', courseId]);
  }

  getCompletedCount(): number {
    return this.courses().filter(c => {
      const progress = c.progress || 0;
      return progress >= 100;
    }).length;
  }

  getInProgressCount(): number {
    return this.courses().filter(c => !c.completed && c.progress > 0).length;
  }

  formatProgress(progress: number): string {
    // Limiter la progression à 100% maximum
    const limitedProgress = Math.min(100, Math.max(0, progress));
    return limitedProgress.toFixed(0);
  }

  // Limiter la progression à 100% maximum pour l'affichage
  getLimitedProgress(progress: number): number {
    return Math.min(100, Math.max(0, progress));
  }

  navigateToHome(): void {
    this.router.navigate(['/student/home']);
  }

  navigateBack(): void {
    this.router.navigate(['/student/home']);
  }
}



