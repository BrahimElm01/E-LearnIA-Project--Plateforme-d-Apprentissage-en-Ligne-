import { Component, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ActivatedRoute, Router, RouterModule } from '@angular/router';
import { CourseService } from '../../../services/course.service';
import { Course } from '../../../models/course.model';
import { Lesson } from '../../../models/lesson.model';
import { DomSanitizer, SafeHtml } from '@angular/platform-browser';

@Component({
  selector: 'app-course-reader',
  standalone: true,
  imports: [CommonModule, RouterModule],
  templateUrl: './course-reader.component.html',
  styleUrl: './course-reader.component.css'
})
export class CourseReaderComponent implements OnInit {
  course = signal<Course | null>(null);
  lessons = signal<Lesson[]>([]);
  currentLesson = signal<Lesson | null>(null);
  currentLessonIndex = signal<number>(0);
  isLoading = signal(false);
  errorMessage = signal<string | null>(null);
  sidebarOpen = signal<boolean>(true);
  completedLessons = signal<Set<number>>(new Set());

  constructor(
    private route: ActivatedRoute,
    private router: Router,
    private courseService: CourseService,
    private sanitizer: DomSanitizer
  ) {}

  ngOnInit(): void {
    const courseIdParam = this.route.snapshot.paramMap.get('courseId');
    const lessonIdParam = this.route.snapshot.queryParamMap.get('lesson');
    
    if (!courseIdParam) {
      this.errorMessage.set('ID de cours invalide');
      return;
    }
    
    const courseId = Number(courseIdParam);
    if (isNaN(courseId) || courseId <= 0) {
      this.errorMessage.set('ID de cours invalide');
      return;
    }

    this.loadCourse(courseId);
    this.loadLessons(courseId, lessonIdParam ? Number(lessonIdParam) : null);
  }

  loadCourse(courseId: number): void {
    this.isLoading.set(true);
    this.courseService.getCourseDetails(courseId).subscribe({
      next: (course) => {
        this.course.set(course);
        this.isLoading.set(false);
      },
      error: (error: any) => {
        console.error('Error loading course', error);
        this.errorMessage.set('Erreur lors du chargement du cours');
        this.isLoading.set(false);
      }
    });
  }

  loadLessons(courseId: number, selectedLessonId: number | null = null): void {
    this.courseService.getCourseLessons(courseId).subscribe({
      next: (lessons) => {
        // Trier les leçons par orderIndex
        const sortedLessons = [...lessons].sort((a, b) => a.orderIndex - b.orderIndex);
        this.lessons.set(sortedLessons);
        
        // Charger les leçons complétées
        this.loadCompletedLessons(courseId);
        
        // Sélectionner la leçon
        if (selectedLessonId) {
          const lesson = sortedLessons.find(l => l.id === selectedLessonId);
          if (lesson) {
            this.selectLesson(lesson, sortedLessons.indexOf(lesson));
          } else {
            // Si la leçon n'existe pas, sélectionner la première
            this.selectLesson(sortedLessons[0], 0);
          }
        } else {
          // Sélectionner la première leçon par défaut
          this.selectLesson(sortedLessons[0], 0);
        }
      },
      error: (error: any) => {
        console.error('Error loading lessons', error);
        this.errorMessage.set('Erreur lors du chargement des leçons');
      }
    });
  }

  loadCompletedLessons(courseId: number): void {
    this.courseService.getStudentCourses().subscribe({
      next: (courses) => {
        const course = courses.find(c => c.id === courseId);
        if (course && course.progress > 0) {
          const totalLessons = this.lessons().length;
          if (totalLessons > 0) {
            const completedCount = Math.round((course.progress / 100) * totalLessons);
            const completed = new Set<number>();
            const sortedLessons = [...this.lessons()].sort((a, b) => a.orderIndex - b.orderIndex);
            for (let i = 0; i < completedCount && i < sortedLessons.length; i++) {
              completed.add(sortedLessons[i].id);
            }
            this.completedLessons.set(completed);
          }
        }
      },
      error: (error) => {
        console.warn('Could not load course progress', error);
        this.completedLessons.set(new Set());
      }
    });
  }

  selectLesson(lesson: Lesson, index: number): void {
    this.currentLesson.set(lesson);
    this.currentLessonIndex.set(index);
    
    // Mettre à jour l'URL sans recharger la page
    this.router.navigate([], {
      relativeTo: this.route,
      queryParams: { lesson: lesson.id },
      queryParamsHandling: 'merge'
    });
  }

  formatLessonContent(content: string): SafeHtml {
    if (!content) return '';
    
    // Fonction pour échapper le HTML
    const escapeHtml = (text: string): string => {
      const map: { [key: string]: string } = {
        '&': '&amp;',
        '<': '&lt;',
        '>': '&gt;',
        '"': '&quot;',
        "'": '&#039;'
      };
      return text.replace(/[&<>"']/g, (m) => map[m]);
    };
    
    let formatted = content;
    
    // Parser les blocs de code (format: ```lang\ncode\n```)
    formatted = formatted.replace(/```(\w+)?\n([\s\S]*?)```/g, (match, lang, code) => {
      const language = lang || 'text';
      const escapedCode = escapeHtml(code);
      return `__CODE_BLOCK_START__${language}__CODE_BLOCK_SEP__${escapedCode}__CODE_BLOCK_END__`;
    });
    
    // Parser les tableaux (format: |col1|col2|\n|---|---|\n|val1|val2|)
    formatted = formatted.replace(/\|(.+)\|\n\|([-|:]+)\|\n((?:\|.+\|\n?)+)/g, (match, header, separator, rows) => {
      const headers = header.split('|').filter((h: string) => h.trim()).map((h: string) => escapeHtml(h.trim()));
      const rowLines = rows.split('\n').filter((line: string) => line.trim());
      
      let tableHtml = '__TABLE_START__';
      headers.forEach((header: string) => {
        tableHtml += `__TH__${header}__TH_END__`;
      });
      tableHtml += '__TABLE_HEAD_END__';
      
      rowLines.forEach((row: string) => {
        const cells = row.split('|').filter((c: string) => c.trim()).map((c: string) => escapeHtml(c.trim()));
        if (cells.length > 0) {
          tableHtml += '__TR_START__';
          cells.forEach((cell: string) => {
            tableHtml += `__TD__${cell}__TD_END__`;
          });
          tableHtml += '__TR_END__';
        }
      });
      
      tableHtml += '__TABLE_END__';
      return tableHtml;
    });
    
    // Échapper tout le HTML restant
    formatted = escapeHtml(formatted);
    
    // Restaurer les blocs de code
    formatted = formatted.replace(/__CODE_BLOCK_START__(\w+)__CODE_BLOCK_SEP__([\s\S]*?)__CODE_BLOCK_END__/g, 
      '<pre class="code-block"><code class="language-$1">$2</code></pre>');
    
    // Restaurer les tableaux
    formatted = formatted.replace(/__TABLE_START__(.*?)__TABLE_END__/g, (match, content) => {
      const parts = content.split('__TABLE_HEAD_END__');
      const headerPart = parts[0] || '';
      const rowsPart = parts[1] || '';
      
      const headers = headerPart.split('__TH__').filter((h: string) => h && !h.includes('__TH_END__'));
      const rowsMatch = rowsPart.match(/__TR_START__(.*?)__TR_END__/g) || [];
      
      let tableHtml = '<table class="content-table"><thead><tr>';
      headers.forEach((header: string) => {
        const cleanHeader = header.replace(/__TH_END__/g, '');
        if (cleanHeader) {
          tableHtml += `<th>${cleanHeader}</th>`;
        }
      });
      tableHtml += '</tr></thead><tbody>';
      
      rowsMatch.forEach((row: string) => {
        const rowContent = row.replace(/__TR_START__/g, '').replace(/__TR_END__/g, '');
        const cells = rowContent.split('__TD__').filter((c: string) => c && !c.includes('__TD_END__'));
        if (cells.length > 0) {
          tableHtml += '<tr>';
          cells.forEach((cell: string) => {
            const cleanCell = cell.replace(/__TD_END__/g, '');
            if (cleanCell) {
              tableHtml += `<td>${cleanCell}</td>`;
            }
          });
          tableHtml += '</tr>';
        }
      });
      
      tableHtml += '</tbody></table>';
      return tableHtml;
    });
    
    // Parser les titres
    formatted = formatted.replace(/^### (.*)$/gm, '<h3>$1</h3>');
    formatted = formatted.replace(/^## (.*)$/gm, '<h2>$1</h2>');
    formatted = formatted.replace(/^# (.*)$/gm, '<h1>$1</h1>');
    
    // Parser les listes à puces
    const lines = formatted.split('\n');
    let inList = false;
    let listItems: string[] = [];
    let result: string[] = [];
    
    lines.forEach((line: string) => {
      const bulletMatch = line.match(/^[-*] (.+)$/);
      if (bulletMatch) {
        if (!inList) {
          inList = true;
          listItems = [];
        }
        listItems.push(`<li>${bulletMatch[1]}</li>`);
      } else {
        if (inList) {
          result.push(`<ul>${listItems.join('')}</ul>`);
          inList = false;
          listItems = [];
        }
        result.push(line);
      }
    });
    
    if (inList) {
      result.push(`<ul>${listItems.join('')}</ul>`);
    }
    
    formatted = result.join('\n');
    
    // Parser les listes numérotées
    const lines2 = formatted.split('\n');
    let inOrderedList = false;
    let orderedItems: string[] = [];
    let result2: string[] = [];
    
    lines2.forEach((line: string) => {
      const orderedMatch = line.match(/^\d+\. (.+)$/);
      if (orderedMatch) {
        if (!inOrderedList) {
          inOrderedList = true;
          orderedItems = [];
        }
        orderedItems.push(`<li>${orderedMatch[1]}</li>`);
      } else {
        if (inOrderedList) {
          result2.push(`<ol>${orderedItems.join('')}</ol>`);
          inOrderedList = false;
          orderedItems = [];
        }
        result2.push(line);
      }
    });
    
    if (inOrderedList) {
      result2.push(`<ol>${orderedItems.join('')}</ol>`);
    }
    
    formatted = result2.join('\n');
    
    // Parser le code inline (format: `code`)
    formatted = formatted.replace(/`([^`\n]+)`/g, '<code class="inline-code">$1</code>');
    
    // Convertir les sauts de ligne en <br>
    formatted = formatted.replace(/\n/g, '<br>');
    
    // Parser le texte en gras (format: **texte**)
    formatted = formatted.replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>');
    
    // Parser le texte en italique (format: *texte*)
    formatted = formatted.replace(/\*([^*\n]+?)\*/g, '<em>$1</em>');
    
    return this.sanitizer.bypassSecurityTrustHtml(formatted);
  }

  toggleSidebar(): void {
    this.sidebarOpen.set(!this.sidebarOpen());
  }

  navigateToPreviousLesson(): void {
    const currentIndex = this.currentLessonIndex();
    if (currentIndex > 0) {
      const previousLesson = this.lessons()[currentIndex - 1];
      this.selectLesson(previousLesson, currentIndex - 1);
    }
  }

  navigateToNextLesson(): void {
    const currentIndex = this.currentLessonIndex();
    if (currentIndex < this.lessons().length - 1) {
      const nextLesson = this.lessons()[currentIndex + 1];
      this.selectLesson(nextLesson, currentIndex + 1);
    }
  }

  isLessonCompleted(lessonId: number): boolean {
    return this.completedLessons().has(lessonId);
  }

  navigateBack(): void {
    const courseId = this.route.snapshot.paramMap.get('courseId');
    if (courseId) {
      this.router.navigate(['/student/course', courseId]);
    } else {
      this.router.navigate(['/student/courses']);
    }
  }
}

