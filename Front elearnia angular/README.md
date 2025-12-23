# E-LearnIA - Frontend Angular

Frontend Angular pour la plateforme E-LearnIA, connecté au backend Spring Boot.

## 🚀 Démarrage rapide

### Installation des dépendances

```bash
npm install
```

### Lancer l'application

```bash
npm start
```

L'application sera accessible sur `http://localhost:4200`

## 📁 Structure du projet

Voir `STRUCTURE.md` pour la structure complète du projet.

## ✅ Ce qui est implémenté

### Modèles (Models)
- ✅ User, AuthResponse
- ✅ Course, StudentCourse, TeacherCourse
- ✅ Lesson
- ✅ Quiz, QuizSummary, QuizResult
- ✅ Review
- ✅ GeneratedCourse (pour IA)
- ✅ ChatMessage
- ✅ Notification

### Services
- ✅ AuthService (authentification complète)
- ✅ CourseService (gestion des cours)
- ✅ QuizService (gestion des quizzes)
- ✅ ReviewService (avis)
- ✅ ChatbotService (chatbot IA)
- ✅ NotificationService (notifications)
- ✅ FileUploadService (upload d'images)

### Guards & Interceptors
- ✅ authGuard (authentification requise)
- ✅ teacherGuard (accès professeur)
- ✅ studentGuard (accès étudiant)
- ✅ authInterceptor (ajout automatique du token)

### Composants
- ✅ LoginComponent
- ✅ RegisterComponent
- ✅ HomeComponent (étudiant)
- ✅ TeacherHomeComponent
- ✅ CoursesComponent (liste des cours)

### Routing
- ✅ Configuration complète des routes
- ✅ Lazy loading des composants
- ✅ Protection des routes avec guards

## 📝 Composants à créer

Les composants suivants doivent encore être créés (structure de base prête) :

### Étudiant
- CourseDetailComponent
- QuizComponent
- QuizzesComponent
- ProfileComponent
- ChatbotComponent

### Professeur
- TeacherCoursesComponent
- CreateCourseComponent
- EditCourseComponent
- AnalyticsComponent
- StudentProgressComponent
- AIGeneratorComponent
- GenerateQuizComponent

## 🔧 Configuration

### Base URL
Par défaut : `http://localhost:8080`

Pour changer, modifier la propriété `baseUrl` dans chaque service.

### Authentification
- Token stocké dans `localStorage`
- Interceptor HTTP ajoute automatiquement le token Bearer
- Guards protègent les routes selon le rôle

## 🎨 Styles

- Design moderne avec gradient noir
- Responsive design
- Support du dark mode (à implémenter)

## 📦 Dépendances

Les dépendances principales sont déjà dans `package.json`. Pour Angular Material :

```bash
ng add @angular/material
```

## 🔄 Prochaines étapes

1. Créer les composants manquants
2. Implémenter le dark mode
3. Ajouter Angular Material pour les composants UI avancés
4. Implémenter la gestion des erreurs globales
5. Ajouter les tests unitaires

## 📚 Documentation

- [Angular Documentation](https://angular.io/docs)
- [Angular Material](https://material.angular.io/)
