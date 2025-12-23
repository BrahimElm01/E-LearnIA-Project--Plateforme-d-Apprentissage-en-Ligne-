# Structure du Frontend Angular E-LearnIA

## 📁 Structure des dossiers

```
src/app/
├── models/                    # Modèles TypeScript
│   ├── user.model.ts
│   ├── course.model.ts
│   ├── lesson.model.ts
│   ├── quiz.model.ts
│   ├── review.model.ts
│   ├── generated-course.model.ts
│   ├── chat-message.model.ts
│   └── notification.model.ts
│
├── services/                  # Services Angular (API calls)
│   ├── auth.service.ts
│   ├── course.service.ts
│   ├── quiz.service.ts
│   ├── review.service.ts
│   ├── chatbot.service.ts
│   ├── notification.service.ts
│   └── file-upload.service.ts
│
├── guards/                    # Route guards
│   └── auth.guard.ts
│
├── interceptors/             # HTTP interceptors
│   └── auth.interceptor.ts
│
├── components/               # Composants Angular
│   ├── login/
│   ├── register/
│   ├── student/
│   │   ├── home/
│   │   ├── courses/
│   │   ├── course-detail/
│   │   ├── quiz/
│   │   ├── quizzes/
│   │   ├── profile/
│   │   └── chatbot/
│   └── teacher/
│       ├── home/
│       ├── courses/
│       ├── create-course/
│       ├── edit-course/
│       ├── analytics/
│       ├── student-progress/
│       ├── ai-generator/
│       └── generate-quiz/
│
├── app.routes.ts             # Configuration des routes
├── app.config.ts            # Configuration de l'application
└── app.ts                   # Composant racine
```

## 🚀 Fonctionnalités implémentées

### ✅ Modèles (Models)
- User, AuthResponse
- Course, StudentCourse, TeacherCourse, CourseAnalytics
- Lesson
- Quiz, QuizSummary, QuizResult, Question
- Review
- GeneratedCourse, GeneratedLesson, GeneratedQuiz
- ChatMessage
- Notification

### ✅ Services
- AuthService (login, register, logout, token management)
- CourseService (cours étudiants/professeurs, IA)
- QuizService (quizzes standalone et liés aux cours)
- ReviewService (avis étudiants, approbation professeurs)
- ChatbotService (chatbot IA)
- NotificationService (notifications)
- FileUploadService (upload d'images)

### ✅ Guards
- authGuard (authentification requise)
- teacherGuard (accès professeur uniquement)
- studentGuard (accès étudiant uniquement)

### ✅ Composants créés
- LoginComponent
- RegisterComponent
- HomeComponent (étudiant)
- TeacherHomeComponent

### 📝 Composants à créer
- StudentCoursesComponent
- CourseDetailComponent
- QuizComponent
- QuizzesComponent
- ProfileComponent
- ChatbotComponent
- TeacherCoursesComponent
- CreateCourseComponent
- EditCourseComponent
- AnalyticsComponent
- StudentProgressComponent
- AIGeneratorComponent
- GenerateQuizComponent

## 🔧 Configuration

### Base URL
Tous les services utilisent `http://localhost:8080` comme base URL.
Pour changer, modifier la propriété `baseUrl` dans chaque service.

### Authentification
- Token stocké dans `localStorage` avec la clé `auth_token`
- User stocké dans `localStorage` avec la clé `auth_user`
- Interceptor HTTP ajoute automatiquement le token Bearer

## 📦 Dépendances nécessaires

```json
{
  "@angular/animations": "^21.0.0",
  "@angular/common": "^21.0.0",
  "@angular/forms": "^21.0.0",
  "@angular/material": "^21.0.0"
}
```

## 🎨 Styles

- Design moderne avec gradient noir
- Responsive design
- Support du dark mode (à implémenter)

## 🔄 Prochaines étapes

1. Créer les composants manquants
2. Implémenter le dark mode
3. Ajouter Angular Material pour les composants UI
4. Implémenter la gestion des erreurs globales
5. Ajouter les tests unitaires








