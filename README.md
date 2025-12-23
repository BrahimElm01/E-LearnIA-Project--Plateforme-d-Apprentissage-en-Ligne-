# 🎓 E-LearnIA - Plateforme d'Apprentissage en Ligne

<div align="center">

![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)
![Spring Boot](https://img.shields.io/badge/Spring%20Boot-3.3.5-brightgreen.svg)
![Flutter](https://img.shields.io/badge/Flutter-3.9.2-02569B.svg?logo=flutter)
![Angular](https://img.shields.io/badge/Angular-21.0.0-DD0031.svg?logo=angular)
![License](https://img.shields.io/badge/license-MIT-green.svg)

**Une plateforme complète d'apprentissage en ligne avec génération de cours par IA, quiz interactifs, et suivi de progression.**

[Fonctionnalités](#-fonctionnalités) • [Architecture](#-architecture) • [Installation](#-installation) • [Documentation](#-documentation) • [Contribution](#-contribution)

</div>

---

## 📋 Table des Matières

- [À Propos](#-à-propos)
- [Fonctionnalités](#-fonctionnalités)
- [Architecture](#-architecture)
- [Technologies Utilisées](#-technologies-utilisées)
- [Prérequis](#-prérequis)
- [Installation](#-installation)
- [Configuration](#-configuration)
- [Utilisation](#-utilisation)
- [Structure du Projet](#-structure-du-projet)
- [API Endpoints](#-api-endpoints)
- [Diagrammes](#-diagrammes)
- [Screenshots](#-screenshots)
- [Contribution](#-contribution)
- [Licence](#-licence)

---

## 🎯 À Propos

E-LearnIA est une plateforme d'apprentissage en ligne moderne qui permet aux professeurs de créer et gérer des cours, et aux étudiants de suivre leur progression. La plateforme intègre l'intelligence artificielle pour générer automatiquement des cours et des quiz, offrant une expérience d'apprentissage personnalisée.

### Caractéristiques Principales

- 🎓 **Gestion de Cours** : Création, modification et suppression de cours avec leçons vidéo
- 🤖 **Génération IA** : Génération automatique de cours et quiz avec l'IA
- 📊 **Analytics** : Tableaux de bord détaillés pour professeurs et étudiants
- 📱 **Multi-plateforme** : Application mobile Flutter et interface web Angular
- 🔐 **Sécurité** : Authentification JWT avec support biométrique (Face ID / Empreinte)
- 📈 **Suivi de Progression** : Suivi détaillé de la progression des étudiants
- 🎯 **Quiz Interactifs** : Quiz avec tentatives multiples et scores détaillés

---

## ✨ Fonctionnalités

### Pour les Étudiants 👨‍🎓

- ✅ Inscription et authentification sécurisée
- ✅ Parcourir et s'inscrire à des cours
- ✅ Suivre des leçons vidéo (YouTube, Vimeo, fichiers locaux)
- ✅ Passer des quiz et voir les résultats
- ✅ Suivre sa progression dans chaque cours
- ✅ Noter et commenter les cours
- ✅ Accéder à des quiz standalone
- ✅ Recevoir des notifications
- ✅ Chatbot IA pour assistance

### Pour les Professeurs 👨‍🏫

- ✅ Création et gestion de cours
- ✅ Génération automatique de cours avec IA
- ✅ Création et modification de leçons
- ✅ Création et gestion de quiz
- ✅ Analytics détaillés (étudiants, progression, scores)
- ✅ Suivi de la progression des étudiants
- ✅ Réinitialisation de la progression
- ✅ Gestion des scores de quiz
- ✅ Upload de fichiers (images, vidéos)

---

## 🏗️ Architecture

Le projet est organisé en trois parties principales :

```
E-LearnIA/
├── elearnia-backend/          # Backend Spring Boot
├── front elearnia/            # Application Flutter Mobile
└── elearnia angular/          # Application Web Angular
```

### Architecture Globale

```
┌─────────────────┐         ┌──────────────────┐         ┌──────────────┐
│  Flutter App    │◄───────►│  Spring Boot API  │◄───────►│   MySQL DB   │
│  (Mobile)       │  HTTP   │  (Backend)        │   JPA   │              │
└─────────────────┘  + JWT  └──────────────────┘         └──────────────┘
                              │
┌─────────────────┐           │
│  Angular App   │◄──────────┘
│  (Web)          │  HTTP + JWT
└─────────────────┘
```

### Architecture Backend (Spring Boot)

```
┌─────────────────────────────────────┐
│      Controllers (REST API)         │
├─────────────────────────────────────┤
│      Services (Business Logic)      │
├─────────────────────────────────────┤
│      Repositories (Data Access)     │
├─────────────────────────────────────┤
│      Entities (JPA)               │
└─────────────────────────────────────┘
```

---

## 🛠️ Technologies Utilisées

### Backend
- **Java 23** - Langage de programmation
- **Spring Boot 3.3.5** - Framework backend
- **Spring Security** - Authentification et autorisation
- **JWT** - JSON Web Tokens pour l'authentification
- **Spring Data JPA** - Accès aux données
- **Hibernate** - ORM
- **MySQL 8** - Base de données
- **Maven** - Gestion des dépendances

### Frontend Flutter
- **Flutter 3.9.2** - Framework mobile
- **Dart** - Langage de programmation
- **http** - Client HTTP
- **flutter_secure_storage** - Stockage sécurisé (JWT)
- **local_auth** - Authentification biométrique
- **video_player** - Lecteur vidéo
- **youtube_player_flutter** - Intégration YouTube

### Frontend Angular
- **Angular 21.0.0** - Framework web
- **TypeScript 5.9.2** - Langage de programmation
- **Angular Material** - Composants UI
- **RxJS** - Programmation réactive

### IA & Services Externes
- **OpenAI API** - Chatbot IA
- **Hugging Face** - Génération de cours avec IA
- **YouTube API** - Intégration vidéo

---

## 📦 Prérequis

### Pour le Backend
- Java 23 ou supérieur
- Maven 3.6+
- MySQL 8.0+
- IDE (IntelliJ IDEA, Eclipse, VS Code)

### Pour Flutter
- Flutter SDK 3.9.2+
- Dart 3.9.2+
- Android Studio / Xcode (pour mobile)
- VS Code ou Android Studio

### Pour Angular
- Node.js 18+
- npm 11.6.2+
- Angular CLI 21.0.3+

---

## 🚀 Installation

### 1. Cloner le Repository

```bash
git clone https://github.com/votre-username/elearnia.git
cd elearnia
```

### 2. Configuration de la Base de Données

```bash
# Créer la base de données
mysql -u root -p
CREATE DATABASE elearnia_db;
EXIT;
```

### 3. Installation du Backend

```bash
cd elearnia-backend

# Configurer application.properties
# Modifier les paramètres de connexion à la base de données dans:
# src/main/resources/application.properties

# Installer les dépendances et compiler
mvn clean install

# Lancer l'application
mvn spring-boot:run
```

Le backend sera accessible sur `http://localhost:8080`

### 4. Installation de l'Application Flutter

```bash
cd "front elearnia/elearnia_app"

# Installer les dépendances
flutter pub get

# Configurer l'URL de l'API
# Modifier lib/config/api_config.dart
# static const String baseUrl = 'http://VOTRE_IP:8080';

# Lancer l'application
flutter run
```

### 5. Installation de l'Application Angular

```bash
cd "elearnia angular"

# Installer les dépendances
npm install

# Configurer l'URL de l'API dans les services
# Modifier les fichiers dans src/app/services/

# Lancer l'application
npm start
```

L'application web sera accessible sur `http://localhost:4200`

---

## ⚙️ Configuration

### Configuration Backend

Fichier: `elearnia-backend/src/main/resources/application.properties`

```properties
# Base de données
spring.datasource.url=jdbc:mysql://localhost:3306/elearnia_db
spring.datasource.username=root
spring.datasource.password=votre_mot_de_passe

# JWT
app.jwt.secret=VotreCleSecreteTresLongue
app.jwt.expiration=86400000

# Upload de fichiers
app.upload.dir=uploads
app.server.base-url=http://localhost:8080

# IA Configuration
chatbot.ai.enabled=true
chatbot.ai.api.key=votre_cle_openai
course.generator.ai.enabled=true
course.generator.ai.huggingface.api.key=votre_cle_huggingface
```

### Configuration Flutter

Fichier: `front elearnia/elearnia_app/lib/config/api_config.dart`

```dart
class ApiConfig {
  static const String baseUrl = 'http://VOTRE_IP:8080';
  // Pour Android Emulator: http://10.0.2.2:8080
  // Pour iOS Simulator: http://localhost:8080
  // Pour appareil physique: http://VOTRE_IP_LOCALE:8080
}
```

### Configuration Angular

Modifier les services dans `elearnia angular/src/app/services/` pour pointer vers votre backend.

---

## 📱 Utilisation

### Démarrage Rapide

1. **Démarrer le Backend**
   ```bash
   cd elearnia-backend
   mvn spring-boot:run
   ```

2. **Démarrer Flutter (Mobile)**
   ```bash
   cd "front elearnia/elearnia_app"
   flutter run
   ```

3. **Démarrer Angular (Web)**
   ```bash
   cd "elearnia angular"
   npm start
   ```

### Créer un Compte Professeur

1. Lancer l'application (Flutter ou Angular)
2. Cliquer sur "S'inscrire"
3. Remplir le formulaire avec le rôle "TEACHER"
4. Se connecter avec vos identifiants

### Créer un Cours

1. Se connecter en tant que professeur
2. Aller dans "Mes Cours"
3. Cliquer sur "Créer un Cours" ou "Générer avec IA"
4. Remplir les informations du cours
5. Ajouter des leçons et un quiz

### S'Inscrire à un Cours (Étudiant)

1. Se connecter en tant qu'étudiant
2. Parcourir les cours disponibles
3. Cliquer sur "S'inscrire"
4. Commencer à suivre les leçons

---

## 📁 Structure du Projet

```
elearnia/
├── elearnia-backend/                 # Backend Spring Boot
│   ├── src/main/java/com/elearnia/
│   │   ├── controller/               # Contrôleurs REST
│   │   ├── service/                  # Services métier
│   │   ├── repository/               # Repositories JPA
│   │   ├── entities/                 # Entités JPA
│   │   ├── dto/                      # Data Transfer Objects
│   │   ├── security/                 # Configuration sécurité
│   │   └── config/                   # Configuration
│   ├── src/main/resources/
│   │   └── application.properties    # Configuration
│   ├── diagrammes/                   # Diagrammes PlantUML
│   └── pom.xml                       # Dépendances Maven
│
├── front elearnia/                   # Application Flutter
│   └── elearnia_app/
│       ├── lib/
│       │   ├── config/               # Configuration
│       │   ├── models/               # Modèles de données
│       │   ├── screens/              # Écrans
│       │   ├── services/             # Services API
│       │   └── widgets/              # Widgets réutilisables
│       ├── android/                  # Configuration Android
│       ├── ios/                      # Configuration iOS
│       └── pubspec.yaml              # Dépendances Flutter
│
└── elearnia angular/                 # Application Angular
    └── src/
        ├── app/
        │   ├── components/           # Composants
        │   ├── services/             # Services
        │   ├── models/               # Modèles
        │   ├── guards/               # Guards d'authentification
        │   └── interceptors/         # Intercepteurs HTTP
        └── index.html
```

---

## 🔌 API Endpoints

### Authentification

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| POST | `/auth/register` | Inscription |
| POST | `/auth/login` | Connexion |
| GET | `/auth/me` | Obtenir l'utilisateur courant |
| PUT | `/auth/profile` | Mettre à jour le profil |

### Étudiant

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/student/courses` | Liste de tous les cours |
| POST | `/student/courses/{id}/enroll` | S'inscrire à un cours |
| GET | `/student/courses/my` | Mes cours |
| GET | `/student/courses/{id}` | Détails d'un cours |
| PUT | `/student/courses/{id}/progress` | Mettre à jour la progression |
| GET | `/student/quizzes/course/{id}` | Obtenir le quiz d'un cours |
| POST | `/student/quizzes/course/{id}/submit` | Soumettre un quiz |
| GET | `/student/quizzes/available` | Quiz standalone disponibles |
| POST | `/student/quizzes/{id}/submit` | Soumettre un quiz standalone |

### Professeur

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| POST | `/teacher/courses` | Créer un cours |
| POST | `/teacher/courses/generate` | Générer un cours avec IA |
| GET | `/teacher/courses/my` | Mes cours |
| PUT | `/teacher/courses/{id}` | Modifier un cours |
| DELETE | `/teacher/courses/{id}` | Supprimer un cours |
| POST | `/teacher/courses/{id}/lessons` | Créer une leçon |
| PUT | `/teacher/courses/lessons/{id}` | Modifier une leçon |
| DELETE | `/teacher/courses/lessons/{id}` | Supprimer une leçon |
| POST | `/teacher/courses/{id}/quiz` | Créer un quiz |
| PUT | `/teacher/courses/{id}/quiz` | Modifier un quiz |
| GET | `/teacher/courses/quizzes` | Liste de mes quizzes |
| GET | `/teacher/courses/quizzes/scores` | Scores de tous les quizzes |
| GET | `/teacher/courses/analytics` | Analytics |
| GET | `/teacher/courses/{id}/progress` | Progression des étudiants |

### Fichiers

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| POST | `/api/files/upload` | Upload un fichier |
| GET | `/api/files/{type}/{filename}` | Télécharger un fichier |

> **Note** : Tous les endpoints (sauf `/auth/register` et `/auth/login`) nécessitent un token JWT dans le header `Authorization: Bearer <token>`

---

## 📊 Diagrammes

Le projet contient des diagrammes détaillés dans le dossier `elearnia-backend/diagrammes/` :

### Diagrammes PlantUML

- **01_Entites_Principales.puml** - Diagramme des entités JPA
- **02_Controleurs_Services.puml** - Contrôleurs et services
- **03_Repositories.puml** - Repositories
- **04_Cas_Utilisation_Etudiant.puml** - Cas d'utilisation étudiants
- **05_Cas_Utilisation_Professeur.puml** - Cas d'utilisation professeurs
- **06_Sequence_Authentification.puml** - Flux d'authentification
- **07_Sequence_Progression.puml** - Flux de progression
- **08_Sequence_Quiz.puml** - Flux de quiz
- **09_Sequence_Creation_Cours.puml** - Création de cours
- **10_Architecture_Globale.puml** - Architecture globale
- **11_Architecture_Couches.puml** - Architecture en couches
- **12_Flux_Donnees.puml** - Flux de données
- **13_Modele_Donnees_ER.puml** - Modèle de données ERD
- **14_Securite_JWT.puml** - Sécurité JWT

### Visualisation

Pour visualiser les diagrammes PlantUML :

1. **En ligne** : [PlantUML Server](http://www.plantuml.com/plantuml/uml/)
2. **VS Code** : Extension "PlantUML"
3. **IntelliJ IDEA** : Plugin "PlantUML integration"

Voir `elearnia-backend/diagrammes/README_PLANTUML.md` pour plus de détails.

---

## 📸 Screenshots

<img width="1770" height="1098" alt="Sequence_Progression" src="https://github.com/user-attachments/assets/d89dd186-4fad-4eba-847a-e4116465e0c4" />
<img width="1415" height="834" alt="Sequence_Creation_Cours" src="https://github.com/user-attachments/assets/49210873-09b8-4cbe-b682-f384e90be156" />
<img width="899" height="963" alt="Sequence_Authentification" src="https://github.com/user-attachments/assets/e34a9d9d-8394-465d-bbaf-e5eb386de8b1" />
<img width="626" height="1343" alt="use case prof " src="https://github.com/user-attachments/assets/dcfbcf23-776f-4d5b-abc8-0cab9ea7448b" />
<img width="642" height="869" alt="use case " src="https://github.com/user-attachments/assets/d2f4cd93-5dc1-4798-b148-7eebb9b5f281" />
<img width="2177" height="807" alt="class2" src="https://github.com/user-attachments/assets/4375dfc8-11a1-4914-8c2e-00645cc4b05e" />
<img width="993" height="1116" alt="class1" src="https://github.com/user-attachments/assets/27fb26e4-75ca-46cc-9a9f-f5e8ca7ced75" />


---

## 🤝 Contribution

Les contributions sont les bienvenues ! Pour contribuer :

1. **Fork** le projet
2. Créer une **branche** pour votre fonctionnalité (`git checkout -b feature/AmazingFeature`)
3. **Commit** vos changements (`git commit -m 'Add some AmazingFeature'`)
4. **Push** vers la branche (`git push origin feature/AmazingFeature`)
5. Ouvrir une **Pull Request**

### Guidelines

- Suivre les conventions de code du projet
- Ajouter des tests pour les nouvelles fonctionnalités
- Mettre à jour la documentation si nécessaire
- Respecter les standards de commit (Conventional Commits)


---

<div align="center">

**Fait avec ❤️ par l'équipe E-LearnIA**

⭐ Si ce projet vous a aidé, n'hésitez pas à lui donner une étoile !

</div>

