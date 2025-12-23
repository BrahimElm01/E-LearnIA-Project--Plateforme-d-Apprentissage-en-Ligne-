import { Routes } from '@angular/router';
import { authGuard, teacherGuard, studentGuard } from './guards/auth.guard';

export const routes: Routes = [
  {
    path: '',
    redirectTo: '/login',
    pathMatch: 'full'
  },
  {
    path: 'login',
    loadComponent: () => import('./components/login/login.component').then(m => m.LoginComponent)
  },
  {
    path: 'register',
    loadComponent: () => import('./components/register/register.component').then(m => m.RegisterComponent)
  },
  {
    path: 'student',
    canActivate: [authGuard, studentGuard],
    children: [
      {
        path: 'home',
        loadComponent: () => import('./components/student/home/home.component').then(m => m.HomeComponent)
      },
      {
        path: 'courses',
        loadComponent: () => import('./components/student/courses/courses.component').then(m => m.CoursesComponent)
      },
      {
        path: 'course/:id',
        loadComponent: () => import('./components/student/course-detail/course-detail.component').then(m => m.CourseDetailComponent)
      },
      {
        path: 'course/:courseId/read',
        loadComponent: () => import('./components/student/course-reader/course-reader.component').then(m => m.CourseReaderComponent)
      },
      {
        path: 'course/:courseId/lesson/:lessonId',
        loadComponent: () => import('./components/student/lesson/lesson').then(m => m.LessonComponent)
      },
      {
        path: 'course/:courseId/lesson/:lessonId/quiz',
        loadComponent: () => import('./components/student/quiz/quiz.component').then(m => m.QuizComponent)
      },
      {
        path: 'course/:courseId/quiz',
        loadComponent: () => import('./components/student/quiz/quiz.component').then(m => m.QuizComponent)
      },
      {
        path: 'quizzes',
        loadComponent: () => import('./components/student/quizzes/quizzes.component').then(m => m.QuizzesComponent)
      },
      {
        path: 'quiz/:id',
        loadComponent: () => import('./components/student/quiz/quiz.component').then(m => m.QuizComponent)
      },
      {
        path: 'profile',
        loadComponent: () => import('./components/student/profile/profile.component').then(m => m.ProfileComponent)
      },
      {
        path: 'chatbot',
        loadComponent: () => import('./components/student/chatbot/chatbot.component').then(m => m.ChatbotComponent)
      },
      {
        path: 'analytics',
        loadComponent: () => import('./components/student/analytics/analytics').then(m => m.AnalyticsComponent)
      },
      {
        path: '',
        redirectTo: 'home',
        pathMatch: 'full'
      }
    ]
  },
  {
    path: 'teacher',
    canActivate: [authGuard, teacherGuard],
    children: [
      {
        path: 'home',
        loadComponent: () => import('./components/teacher/home/home.component').then(m => m.TeacherHomeComponent)
      },
      {
        path: 'courses',
        loadComponent: () => import('./components/teacher/courses/courses.component').then(m => m.TeacherCoursesComponent)
      },
      {
        path: 'course/create',
        loadComponent: () => import('./components/teacher/create-course/create-course.component').then(m => m.CreateCourseComponent)
      },
      {
        path: 'course/:id/edit',
        loadComponent: () => import('./components/teacher/edit-course/edit-course.component').then(m => m.EditCourseComponent)
      },
      {
        path: 'course/:courseId/quiz/edit',
        loadComponent: () => import('./components/teacher/edit-quiz/edit-quiz').then(m => m.EditQuizComponent)
      },
      {
        path: 'analytics',
        loadComponent: () => import('./components/teacher/analytics/analytics.component').then(m => m.AnalyticsComponent)
      },
      {
        path: 'progress/:courseId',
        loadComponent: () => import('./components/teacher/course-student-progress/course-student-progress.component').then(m => m.CourseStudentProgress)
      },
      {
        path: 'progress',
        loadComponent: () => import('./components/teacher/student-progress/student-progress.component').then(m => m.StudentProgressComponent)
      },
      {
        path: 'ai-generator',
        loadComponent: () => import('./components/teacher/ai-generator/ai-generator.component').then(m => m.AIGeneratorComponent)
      },
      {
        path: 'generate-quiz',
        loadComponent: () => import('./components/teacher/generate-quiz/generate-quiz.component').then(m => m.GenerateQuizComponent)
      },
      {
        path: 'quizzes',
        loadComponent: () => import('./components/teacher/quizzes/quizzes').then(m => m.TeacherQuizzesComponent)
      },
      {
        path: 'quiz/:id/edit',
        loadComponent: () => import('./components/teacher/edit-quiz/edit-quiz').then(m => m.EditQuizComponent)
      },
      {
        path: 'profile',
        loadComponent: () => import('./components/teacher/profile/profile.component').then(m => m.TeacherProfileComponent)
      },
      {
        path: '',
        redirectTo: 'home',
        pathMatch: 'full'
      }
    ]
  },
  {
    path: '**',
    redirectTo: '/login'
  }
];
