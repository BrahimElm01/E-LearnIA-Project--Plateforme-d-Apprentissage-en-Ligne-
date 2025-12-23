package com.elearnia.service;

import com.elearnia.entities.Course;
import com.elearnia.entities.Enrollment;
import com.elearnia.model.User;
import com.elearnia.repository.CourseRepository;
import com.elearnia.repository.EnrollmentRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;
import java.time.Duration;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class ChatBotService {

    private final EnrollmentRepository enrollmentRepository;
    private final CourseRepository courseRepository;
    private final WebClient webClient;

    @Value("${chatbot.ai.enabled:true}")
    private boolean aiEnabled;

    @Value("${chatbot.ai.api.key:}")
    private String aiApiKey;

    public String processMessage(String message, User student) {
        String lowerMessage = message.toLowerCase().trim();

        // Récupérer les données de l'étudiant pour le contexte
        List<Enrollment> enrollments = enrollmentRepository.findByStudentId(student.getId());
        List<Course> allCourses = courseRepository.findAll();

        // Construire le contexte de l'étudiant
        String context = buildStudentContext(student, enrollments, allCourses);

        // Vérifier si c'est une question spécifique qui nécessite des données contextuelles
        String contextualResponse = handleContextualQueries(lowerMessage, student, enrollments, allCourses);
        if (contextualResponse != null) {
            return contextualResponse;
        }

        // Pour toutes les autres questions, utiliser l'IA
        try {
            String aiResponse = callAIAPI(message, context);
            if (aiResponse != null && !aiResponse.trim().isEmpty()) {
                return aiResponse;
            }
        } catch (Exception e) {
            log.error("Erreur lors de l'appel à l'API IA: {}", e.getMessage());
        }

        // Fallback si l'IA ne répond pas
        return generateDefaultResponse(student, enrollments);
    }

    private String buildStudentContext(User student, List<Enrollment> enrollments, List<Course> allCourses) {
        StringBuilder context = new StringBuilder();
        context.append("Tu es un assistant virtuel intelligent pour une plateforme d'apprentissage en ligne appelée E-LearnIA. ");
        context.append("L'étudiant s'appelle ").append(student.getFullName()).append(". ");
        
        if (!enrollments.isEmpty()) {
            long completedCount = enrollments.stream().filter(Enrollment::isCompleted).count();
            context.append("L'étudiant est inscrit à ").append(enrollments.size()).append(" cours");
            if (completedCount > 0) {
                context.append(", dont ").append(completedCount).append(" terminés");
            }
            context.append(". ");
            
            // Ajouter les cours en cours
            List<Enrollment> inProgress = enrollments.stream()
                    .filter(e -> !e.isCompleted())
                    .collect(Collectors.toList());
            if (!inProgress.isEmpty()) {
                context.append("Cours en cours: ");
                for (int i = 0; i < Math.min(inProgress.size(), 3); i++) {
                    if (i > 0) context.append(", ");
                    context.append(inProgress.get(i).getCourse().getTitle())
                            .append(" (").append(String.format("%.0f", inProgress.get(i).getProgress())).append("%)");
                }
                context.append(". ");
            }
        } else {
            context.append("L'étudiant n'est pas encore inscrit à un cours. ");
        }
        
        // Ajouter les catégories disponibles
        Set<String> categories = extractCategories(allCourses);
        if (!categories.isEmpty()) {
            context.append("Catégories de cours disponibles sur la plateforme: ");
            context.append(String.join(", ", categories.stream().limit(10).collect(Collectors.toList())));
            context.append(". ");
        }
        
        // Ajouter la liste des cours disponibles
        if (!allCourses.isEmpty()) {
            context.append("Cours disponibles sur la plateforme: ");
            for (int i = 0; i < Math.min(allCourses.size(), 10); i++) {
                if (i > 0) context.append(", ");
                context.append(allCourses.get(i).getTitle());
            }
            context.append(". ");
        }
        
        // Ajouter toutes les fonctionnalités de l'application
        context.append("\n\nFONCTIONNALITÉS DE LA PLATEFORME:\n");
        context.append("- Navigation par catégories: Les cours sont organisés par domaines (Développement, Design, Business, etc.)\n");
        context.append("- Inscription aux cours: Les étudiants peuvent s'inscrire à plusieurs cours\n");
        context.append("- Suivi de progression: Affichage du pourcentage de complétion pour chaque cours\n");
        context.append("- Leçons vidéo: Chaque cours contient des leçons avec vidéos YouTube ou fichiers vidéo\n");
        context.append("- Quiz: À la fin de chaque cours, un quiz avec 3 tentatives, score minimum 75% pour réussir\n");
        context.append("- Quiz standalone: Quiz indépendants disponibles dans l'onglet 'Quizzes' avec filtres par niveau (Débutant, Intermédiaire, Avancé)\n");
        context.append("- Système de notes: Les étudiants peuvent noter les cours après complétion\n");
        context.append("- Reviews: Les étudiants peuvent laisser des avis sur les cours\n");
        context.append("- Profil étudiant: Gestion du profil, mode sombre, notifications\n");
        context.append("- Notifications: Alertes pour nouvelles inscriptions et complétions de cours\n");
        context.append("- Recherche et filtrage: Par catégories, niveau, progression\n");
        context.append("- Certificats: Après complétion réussie d'un cours\n");
        
        context.append("\nTu peux répondre à TOUTES les questions de l'étudiant, y compris:\n");
        context.append("- Questions sur les fonctionnalités de la plateforme\n");
        context.append("- Définitions techniques (Spring Boot, Flutter, React, etc.)\n");
        context.append("- Questions sur les catégories et cours disponibles\n");
        context.append("- Conseils d'apprentissage et méthodologie\n");
        context.append("- Questions sur la progression et les quiz\n");
        context.append("- Toute autre question éducative ou technique\n");
        
        context.append("\nRéponds de manière amicale, professionnelle et détaillée en français. ");
        context.append("Si la question concerne une fonctionnalité spécifique de la plateforme, donne des détails précis. ");
        context.append("Si c'est une question technique générale, fournis une explication claire et concise.");
        return context.toString();
    }
    
    private Set<String> extractCategories(List<Course> courses) {
        Set<String> categories = new HashSet<>();
        for (Course course : courses) {
            String title = course.getTitle().toLowerCase();
            String description = course.getDescription() != null ? course.getDescription().toLowerCase() : "";
            
            // Détecter les catégories basées sur les mots-clés
            if (title.contains("flutter") || title.contains("dart") || description.contains("flutter")) {
                categories.add("Développement Mobile");
            }
            if (title.contains("spring") || title.contains("java") || description.contains("spring boot")) {
                categories.add("Développement Backend");
            }
            if (title.contains("react") || title.contains("javascript") || title.contains("frontend")) {
                categories.add("Développement Frontend");
            }
            if (title.contains("python") || description.contains("python")) {
                categories.add("Programmation Python");
            }
            if (title.contains("web") || description.contains("web development")) {
                categories.add("Développement Web");
            }
            if (title.contains("design") || title.contains("ui") || title.contains("ux")) {
                categories.add("Design");
            }
            if (title.contains("business") || title.contains("marketing")) {
                categories.add("Business");
            }
            if (title.contains("data") || title.contains("analytics")) {
                categories.add("Data Science");
            }
        }
        if (categories.isEmpty()) {
            categories.add("Développement");
            categories.add("Design");
            categories.add("Business");
            categories.add("Data Science");
        }
        return categories;
    }

    private String handleContextualQueries(String lowerMessage, User student, List<Enrollment> enrollments, List<Course> allCourses) {
        // Questions qui nécessitent des données spécifiques de l'étudiant
        if (lowerMessage.contains("recommand") || lowerMessage.contains("sugg") || lowerMessage.contains("conseil")) {
            return generateRecommendations(student, enrollments, allCourses);
        }

        if (lowerMessage.contains("progress") || lowerMessage.contains("progression") || lowerMessage.contains("avancement")) {
            return generateProgressInfo(enrollments);
        }

        if ((lowerMessage.contains("mes cours") || lowerMessage.contains("mon cours")) && 
            (lowerMessage.contains("liste") || lowerMessage.contains("quels") || lowerMessage.contains("quelles"))) {
            return generateCourseInfo(enrollments, allCourses);
        }

        // Questions sur les catégories disponibles
        if (lowerMessage.contains("catégor") || lowerMessage.contains("categorie") || 
            (lowerMessage.contains("quels") && lowerMessage.contains("disponible"))) {
            return generateCategoriesInfo(allCourses);
        }

        // Questions sur les cours disponibles
        if ((lowerMessage.contains("cours disponible") || lowerMessage.contains("liste des cours")) &&
            !lowerMessage.contains("mes cours")) {
            return generateAvailableCoursesInfo(allCourses);
        }

        // Questions sur les niveaux de quiz
        if (lowerMessage.contains("niveau") && lowerMessage.contains("quiz")) {
            return generateQuizLevelsInfo();
        }

        return null; // Pas de réponse contextuelle, utiliser l'IA
    }

    private String callAIAPI(String message, String context) {
        // Utiliser Hugging Face Inference API (gratuite, pas besoin de clé pour les modèles publics)
        // Modèle: microsoft/DialoGPT-medium ou un modèle de conversation français
        try {
            // Construire le prompt avec le contexte
            String prompt = context + "\n\nÉtudiant: " + message + "\nAssistant:";
            
            Map<String, Object> requestBody = new HashMap<>();
            requestBody.put("inputs", prompt);
            Map<String, Object> parameters = new HashMap<>();
            parameters.put("max_new_tokens", 200);
            parameters.put("temperature", 0.7);
            parameters.put("return_full_text", false);
            requestBody.put("parameters", parameters);

            // Essayer Hugging Face Inference API (gratuite)
            try {
                Object response = webClient.post()
                        .uri("/models/microsoft/DialoGPT-medium")
                        .bodyValue(requestBody)
                        .retrieve()
                        .bodyToMono(Object.class)
                        .timeout(Duration.ofSeconds(15))
                        .block();

                if (response != null) {
                    // Parser la réponse de Hugging Face
                    String aiResponse = parseHuggingFaceResponse(response);
                    if (aiResponse != null && !aiResponse.trim().isEmpty()) {
                        return aiResponse.trim();
                    }
                }
            } catch (Exception e) {
                log.debug("Hugging Face API non disponible, utilisation de la logique intelligente: {}", e.getMessage());
            }

            // Si Hugging Face ne fonctionne pas, utiliser la logique intelligente améliorée
            return generateIntelligentResponse(message, context);
            
        } catch (Exception e) {
            log.warn("Erreur lors de l'appel à l'API IA: {}", e.getMessage());
            return generateIntelligentResponse(message, context);
        }
    }

    @SuppressWarnings("unchecked")
    private String parseHuggingFaceResponse(Object response) {
        try {
            if (response instanceof List) {
                List<?> list = (List<?>) response;
                if (!list.isEmpty()) {
                    Object firstItem = list.get(0);
                    if (firstItem instanceof Map) {
                        Map<String, Object> map = (Map<String, Object>) firstItem;
                        Object generatedText = map.get("generated_text");
                        if (generatedText != null) {
                            String text = generatedText.toString();
                            // Nettoyer la réponse (enlever le prompt si présent)
                            if (text.contains("Assistant:")) {
                                text = text.substring(text.indexOf("Assistant:") + "Assistant:".length()).trim();
                            }
                            return text;
                        }
                    }
                }
            }
        } catch (Exception e) {
            log.debug("Erreur parsing réponse Hugging Face: {}", e.getMessage());
        }
        return null;
    }

    private String generateIntelligentResponse(String message, String context) {
        // Analyser le message et générer une réponse intelligente basée sur le contexte
        String lowerMessage = message.toLowerCase();
        
        // Détecter le type de question
        if (lowerMessage.contains("comment") || lowerMessage.contains("pourquoi") || lowerMessage.contains("explique")) {
            return generateExplanationResponse(message, context);
        }
        
        if (lowerMessage.contains("quand") || lowerMessage.contains("où") || lowerMessage.contains("qui")) {
            return generateFactualResponse(message, context);
        }
        
        if (lowerMessage.contains("aide") || lowerMessage.contains("problème") || lowerMessage.contains("difficulté")) {
            return generateHelpResponse(message, context);
        }
        
        // Réponse générale intelligente
        return generateGeneralResponse(message, context);
    }

    private String generateExplanationResponse(String message, String context) {
        StringBuilder response = new StringBuilder();
        
        if (message.toLowerCase().contains("quiz")) {
            response.append("Voici comment fonctionnent les quiz sur notre plateforme :\n\n");
            response.append("• Les quiz sont disponibles à la fin de chaque cours\n");
            response.append("• Vous avez 3 tentatives par quiz\n");
            response.append("• Un score minimum de 75% est requis pour réussir\n");
            response.append("• Si vous réussissez, le cours est marqué comme complété\n");
            response.append("• Vous pouvez également accéder à des quiz standalone dans l'onglet 'Quizzes'\n\n");
            response.append("Les quiz sont un excellent moyen de valider vos connaissances ! 💪");
        } else if (message.toLowerCase().contains("cours") || message.toLowerCase().contains("formation")) {
            response.append("Sur notre plateforme, vous pouvez :\n\n");
            response.append("• Explorer une variété de cours dans différentes catégories\n");
            response.append("• Vous inscrire aux cours qui vous intéressent\n");
            response.append("• Suivre votre progression en temps réel\n");
            response.append("• Accéder aux leçons vidéo et au contenu multimédia\n");
            response.append("• Passer des quiz pour valider vos compétences\n");
            response.append("• Obtenir des certificats de complétion\n\n");
            response.append("N'hésitez pas à explorer les cours disponibles ! 📚");
        } else {
            response.append("Je comprends votre question. ");
            response.append("Basé sur votre contexte d'apprentissage, ");
            response.append("je peux vous dire que l'apprentissage en ligne nécessite de la régularité et de la pratique. ");
            response.append("N'hésitez pas à me poser des questions plus spécifiques sur vos cours ou votre progression ! 😊");
        }
        
        return response.toString();
    }

    private String generateFactualResponse(String message, String context) {
        StringBuilder response = new StringBuilder();
        response.append("D'après votre profil, ");
        
        if (context.contains("inscrit à")) {
            response.append("vous êtes actuellement inscrit à des cours. ");
            response.append("Vous pouvez consulter vos cours dans l'onglet 'Mes cours' pour plus de détails. ");
        } else {
            response.append("vous n'êtes pas encore inscrit à un cours. ");
            response.append("Je vous recommande d'explorer les cours disponibles et de vous inscrire à ceux qui vous intéressent. ");
        }
        
        response.append("\n\nPour des informations plus précises, n'hésitez pas à me poser des questions spécifiques !");
        return response.toString();
    }

    private String generateHelpResponse(String message, String context) {
        StringBuilder response = new StringBuilder();
        response.append("Je suis là pour vous aider ! 😊\n\n");
        response.append("Voici ce que je peux faire pour vous :\n\n");
        response.append("• 📊 Vous montrer votre progression dans vos cours\n");
        response.append("• 📚 Vous recommander des cours adaptés à vos besoins\n");
        response.append("• 📖 Répondre à vos questions sur la plateforme\n");
        response.append("• 💡 Vous donner des conseils pour réussir vos cours\n");
        response.append("• 🎯 Vous expliquer le fonctionnement des quiz\n\n");
        response.append("Que souhaitez-vous savoir exactement ?");
        return response.toString();
    }

    private String generateGeneralResponse(String message, String context) {
        StringBuilder response = new StringBuilder();
        String lowerMessage = message.toLowerCase();
        
        // Détecter les questions techniques (définitions)
        if (lowerMessage.contains("définition") || lowerMessage.contains("definition") || 
            lowerMessage.contains("c'est quoi") || lowerMessage.contains("qu'est-ce que")) {
            return generateTechnicalDefinition(message, context);
        }
        
        // Détecter les questions sur les fonctionnalités
        if (lowerMessage.contains("fonctionnalité") || lowerMessage.contains("fonction") || 
            lowerMessage.contains("peut") || lowerMessage.contains("comment utiliser")) {
            return generateFeatureExplanation(message, context);
        }
        
        response.append("Merci pour votre question ! ");
        
        // Analyser le contexte et donner une réponse pertinente
        if (context.contains("inscrit à")) {
            response.append("Je vois que vous êtes actif sur la plateforme. ");
            response.append("C'est excellent ! ");
        }
        
        response.append("Pour mieux vous aider, pouvez-vous être plus spécifique ? ");
        response.append("Par exemple, vous pouvez me demander :\n\n");
        response.append("• Votre progression actuelle\n");
        response.append("• Des recommandations de cours\n");
        response.append("• Des informations sur un cours spécifique\n");
        response.append("• De l'aide sur le fonctionnement de la plateforme\n");
        response.append("• Des définitions techniques (Spring Boot, Flutter, etc.)\n");
        response.append("• Les catégories disponibles\n\n");
        response.append("Je suis là pour vous accompagner dans votre apprentissage ! 💪");
        
        return response.toString();
    }
    
    private String generateTechnicalDefinition(String message, String context) {
        String lowerMessage = message.toLowerCase();
        StringBuilder response = new StringBuilder();
        
        // Détecter les technologies mentionnées
        if (lowerMessage.contains("spring boot") || lowerMessage.contains("springboot")) {
            response.append("**Spring Boot** est un framework Java open-source qui simplifie le développement d'applications Java. ");
            response.append("Il permet de créer rapidement des applications web et des microservices avec une configuration minimale.\n\n");
            response.append("**Caractéristiques principales :**\n");
            response.append("• Configuration automatique (auto-configuration)\n");
            response.append("• Serveur embarqué (Tomcat, Jetty)\n");
            response.append("• Production-ready (métriques, health checks)\n");
            response.append("• Écosystème riche (Spring Data, Spring Security, etc.)\n\n");
            response.append("Sur notre plateforme, vous pouvez trouver des cours sur Spring Boot pour apprendre à développer des applications backend modernes ! 🚀");
        } else if (lowerMessage.contains("flutter")) {
            response.append("**Flutter** est un framework de développement mobile open-source créé par Google. ");
            response.append("Il permet de créer des applications natives pour iOS et Android avec un seul codebase.\n\n");
            response.append("**Caractéristiques principales :**\n");
            response.append("• Développement multiplateforme (iOS + Android)\n");
            response.append("• Langage Dart\n");
            response.append("• Interface utilisateur performante (60 FPS)\n");
            response.append("• Hot reload pour un développement rapide\n");
            response.append("• Widgets personnalisables\n\n");
            response.append("Sur notre plateforme, vous pouvez trouver des cours sur Flutter pour devenir développeur mobile ! 📱");
        } else if (lowerMessage.contains("react")) {
            response.append("**React** est une bibliothèque JavaScript open-source développée par Facebook pour créer des interfaces utilisateur. ");
            response.append("Elle est particulièrement utilisée pour le développement web frontend.\n\n");
            response.append("**Caractéristiques principales :**\n");
            response.append("• Composants réutilisables\n");
            response.append("• Virtual DOM pour de meilleures performances\n");
            response.append("• Écosystème riche (React Router, Redux, etc.)\n");
            response.append("• Large communauté et ressources\n\n");
            response.append("Sur notre plateforme, vous pouvez trouver des cours sur React pour maîtriser le développement frontend moderne ! ⚛️");
        } else if (lowerMessage.contains("java")) {
            response.append("**Java** est un langage de programmation orienté objet, multiplateforme et très populaire. ");
            response.append("Il est largement utilisé pour le développement d'applications backend, web et mobiles.\n\n");
            response.append("**Caractéristiques principales :**\n");
            response.append("• Orienté objet\n");
            response.append("• Portable (Write Once, Run Anywhere)\n");
            response.append("• Sécurisé et robuste\n");
            response.append("• Grande communauté et écosystème\n\n");
            response.append("Sur notre plateforme, vous pouvez trouver des cours sur Java et Spring Boot ! ☕");
        } else if (lowerMessage.contains("python")) {
            response.append("**Python** est un langage de programmation interprété, haut niveau et polyvalent. ");
            response.append("Il est très populaire pour le développement web, la data science, l'IA et l'automatisation.\n\n");
            response.append("**Caractéristiques principales :**\n");
            response.append("• Syntaxe simple et lisible\n");
            response.append("• Polyvalent (web, data, IA, etc.)\n");
            response.append("• Bibliothèques riches (Django, Flask, NumPy, Pandas)\n");
            response.append("• Idéal pour débutants\n\n");
            response.append("Sur notre plateforme, vous pouvez trouver des cours sur Python ! 🐍");
        } else {
            // Réponse générique pour les définitions techniques
            response.append("Je comprends que vous cherchez une définition technique. ");
            response.append("Sur notre plateforme E-LearnIA, nous proposons des cours sur diverses technologies :\n\n");
            response.append("• **Développement Backend** : Spring Boot, Java, Node.js\n");
            response.append("• **Développement Frontend** : React, JavaScript, HTML/CSS\n");
            response.append("• **Développement Mobile** : Flutter, React Native\n");
            response.append("• **Data Science** : Python, Machine Learning\n");
            response.append("• **Et bien plus encore !**\n\n");
            response.append("Pouvez-vous me préciser quelle technologie vous intéresse ? Je pourrai vous donner plus de détails et vous recommander des cours adaptés ! 📚");
        }
        
        return response.toString();
    }
    
    private String generateFeatureExplanation(String message, String context) {
        StringBuilder response = new StringBuilder();
        response.append("Voici les principales fonctionnalités de notre plateforme E-LearnIA :\n\n");
        response.append("**📚 Gestion des cours :**\n");
        response.append("• Parcourir les cours par catégories\n");
        response.append("• S'inscrire aux cours qui vous intéressent\n");
        response.append("• Suivre votre progression en temps réel\n\n");
        response.append("**🎥 Contenu d'apprentissage :**\n");
        response.append("• Leçons vidéo (YouTube et fichiers vidéo)\n");
        response.append("• Contenu multimédia interactif\n");
        response.append("• Support de différents formats\n\n");
        response.append("**📝 Système de quiz :**\n");
        response.append("• Quiz à la fin de chaque cours\n");
        response.append("• Quiz standalone avec filtres par niveau\n");
        response.append("• 3 tentatives par quiz, score minimum 75%\n\n");
        response.append("**⭐ Évaluation :**\n");
        response.append("• Noter les cours après complétion\n");
        response.append("• Laisser des avis et reviews\n");
        response.append("• Voir les avis des autres étudiants\n\n");
        response.append("**👤 Profil et personnalisation :**\n");
        response.append("• Gestion du profil utilisateur\n");
        response.append("• Mode sombre\n");
        response.append("• Notifications personnalisées\n\n");
        response.append("N'hésitez pas à explorer toutes ces fonctionnalités ! 🚀");
        return response.toString();
    }
    
    private String generateCategoriesInfo(List<Course> allCourses) {
        Set<String> categories = extractCategories(allCourses);
        StringBuilder response = new StringBuilder();
        response.append("📂 **Catégories disponibles sur la plateforme :**\n\n");
        
        if (categories.isEmpty()) {
            response.append("Les catégories principales sont :\n");
            response.append("• Développement Mobile\n");
            response.append("• Développement Backend\n");
            response.append("• Développement Frontend\n");
            response.append("• Programmation Python\n");
            response.append("• Développement Web\n");
            response.append("• Design\n");
            response.append("• Business\n");
            response.append("• Data Science\n\n");
        } else {
            int index = 1;
            for (String category : categories) {
                response.append(index).append(". ").append(category).append("\n");
                index++;
            }
            response.append("\n");
        }
        
        response.append("Vous pouvez explorer les cours par catégorie depuis l'écran d'accueil ! ");
        response.append("Chaque catégorie regroupe des cours liés au même domaine. 🎯");
        return response.toString();
    }
    
    private String generateAvailableCoursesInfo(List<Course> allCourses) {
        StringBuilder response = new StringBuilder();
        response.append("📚 **Cours disponibles sur la plateforme :**\n\n");
        
        if (allCourses.isEmpty()) {
            response.append("Aucun cours disponible pour le moment. ");
            response.append("Revenez bientôt pour découvrir de nouveaux cours !");
        } else {
            int maxCourses = Math.min(allCourses.size(), 10);
            for (int i = 0; i < maxCourses; i++) {
                Course course = allCourses.get(i);
                response.append((i + 1)).append(". ").append(course.getTitle());
                if (course.getDescription() != null && !course.getDescription().isEmpty()) {
                    String desc = course.getDescription();
                    if (desc.length() > 80) {
                        desc = desc.substring(0, 80) + "...";
                    }
                    response.append("\n   ").append(desc);
                }
                response.append("\n\n");
            }
            if (allCourses.size() > 10) {
                response.append("... et ").append(allCourses.size() - 10).append(" autres cours !\n\n");
            }
            response.append("Explorez ces cours et inscrivez-vous à ceux qui vous intéressent ! 🎓");
        }
        
        return response.toString();
    }
    
    private String generateQuizLevelsInfo() {
        StringBuilder response = new StringBuilder();
        response.append("📊 **Niveaux de quiz disponibles :**\n\n");
        response.append("Les quiz sur notre plateforme sont organisés en trois niveaux :\n\n");
        response.append("**1. Débutant (BEGINNER)**\n");
        response.append("• Pour les étudiants qui commencent\n");
        response.append("• Questions de base et fondamentales\n");
        response.append("• Parfait pour valider les concepts essentiels\n\n");
        response.append("**2. Intermédiaire (INTERMEDIATE)**\n");
        response.append("• Pour les étudiants avec des connaissances de base\n");
        response.append("• Questions plus approfondies\n");
        response.append("• Application pratique des concepts\n\n");
        response.append("**3. Avancé (ADVANCED)**\n");
        response.append("• Pour les étudiants expérimentés\n");
        response.append("• Questions complexes et défis\n");
        response.append("• Maîtrise approfondie des sujets\n\n");
        response.append("Vous pouvez filtrer les quiz par niveau dans l'onglet 'Quizzes' ! ");
        response.append("Chaque quiz indique son niveau de difficulté. 🎯");
        return response.toString();
    }

    private String generateGreeting(User student, List<Enrollment> enrollments) {
        StringBuilder response = new StringBuilder();
        response.append("Bonjour ").append(student.getFullName()).append(" ! 👋\n\n");
        response.append("Je suis votre assistant virtuel. Je peux vous aider à :\n");
        response.append("• Voir votre progression\n");
        response.append("• Obtenir des recommandations de cours\n");
        response.append("• Répondre à vos questions\n\n");
        
        if (!enrollments.isEmpty()) {
            long completedCount = enrollments.stream().filter(Enrollment::isCompleted).count();
            response.append("Vous êtes actuellement inscrit à ").append(enrollments.size()).append(" cours");
            if (completedCount > 0) {
                response.append(" et vous en avez terminé ").append(completedCount);
            }
            response.append(".\n\n");
        }
        
        response.append("Comment puis-je vous aider aujourd'hui ?");
        return response.toString();
    }

    private String generateRecommendations(User student, List<Enrollment> enrollments, List<Course> allCourses) {
        StringBuilder response = new StringBuilder();
        response.append("📚 Recommandations de cours pour vous :\n\n");

        // Trouver les cours non inscrits
        List<Long> enrolledCourseIds = enrollments.stream()
                .map(e -> e.getCourse().getId())
                .collect(Collectors.toList());

        List<Course> availableCourses = allCourses.stream()
                .filter(c -> !enrolledCourseIds.contains(c.getId()))
                .limit(5)
                .collect(Collectors.toList());

        if (availableCourses.isEmpty()) {
            response.append("Vous êtes déjà inscrit à tous les cours disponibles ! 🎉\n");
            response.append("Continuez votre apprentissage et n'hésitez pas à revenir pour de nouveaux cours.");
        } else {
            response.append("Voici ").append(availableCourses.size()).append(" cours qui pourraient vous intéresser :\n\n");
            for (int i = 0; i < availableCourses.size(); i++) {
                Course course = availableCourses.get(i);
                response.append((i + 1)).append(". ").append(course.getTitle()).append("\n");
                if (course.getDescription() != null && !course.getDescription().isEmpty()) {
                    String desc = course.getDescription();
                    if (desc.length() > 100) {
                        desc = desc.substring(0, 100) + "...";
                    }
                    response.append("   ").append(desc).append("\n");
                }
                response.append("\n");
            }
            response.append("N'hésitez pas à explorer ces cours pour enrichir vos compétences !");
        }

        return response.toString();
    }

    private String generateProgressInfo(List<Enrollment> enrollments) {
        if (enrollments.isEmpty()) {
            return "Vous n'êtes pas encore inscrit à un cours.\n\nJe vous recommande de parcourir les cours disponibles et de vous inscrire à ceux qui vous intéressent !";
        }

        StringBuilder response = new StringBuilder();
        response.append("📊 Votre progression :\n\n");

        long completedCount = enrollments.stream().filter(Enrollment::isCompleted).count();
        long inProgressCount = enrollments.size() - completedCount;

        response.append("• Cours terminés : ").append(completedCount).append("\n");
        response.append("• Cours en cours : ").append(inProgressCount).append("\n\n");

        // Afficher les cours en cours avec leur progression
        List<Enrollment> inProgress = enrollments.stream()
                .filter(e -> !e.isCompleted())
                .collect(Collectors.toList());

        if (!inProgress.isEmpty()) {
            response.append("Cours en cours :\n");
            for (Enrollment enrollment : inProgress) {
                response.append("• ").append(enrollment.getCourse().getTitle())
                        .append(" : ").append(String.format("%.1f", enrollment.getProgress())).append("%\n");
            }
            response.append("\n");
        }

        if (completedCount > 0) {
            response.append("Félicitations pour vos cours terminés ! 🎉\n");
        }

        response.append("\nContinuez vos efforts, vous progressez bien ! 💪");
        return response.toString();
    }

    private String generateCourseInfo(List<Enrollment> enrollments, List<Course> allCourses) {
        StringBuilder response = new StringBuilder();
        
        if (enrollments.isEmpty()) {
            response.append("Vous n'êtes pas encore inscrit à un cours.\n\n");
            response.append("Voici les cours disponibles :\n\n");
            List<Course> courses = allCourses.stream().limit(5).collect(Collectors.toList());
            for (int i = 0; i < courses.size(); i++) {
                response.append((i + 1)).append(". ").append(courses.get(i).getTitle()).append("\n");
            }
            response.append("\nExplorez ces cours et inscrivez-vous à ceux qui vous intéressent !");
        } else {
            response.append("📖 Vos cours :\n\n");
            for (Enrollment enrollment : enrollments) {
                Course course = enrollment.getCourse();
                response.append("• ").append(course.getTitle());
                if (enrollment.isCompleted()) {
                    response.append(" ✅ (Terminé)");
                } else {
                    response.append(" - ").append(String.format("%.1f", enrollment.getProgress())).append("% complété");
                }
                response.append("\n");
            }
            response.append("\nContinuez votre apprentissage ! 💪");
        }

        return response.toString();
    }

    private String generateQuizInfo() {
        return "📝 Informations sur les quiz :\n\n" +
                "• Les quiz sont disponibles à la fin de chaque cours\n" +
                "• Vous avez 3 tentatives par quiz\n" +
                "• Un score de 75% ou plus est requis pour réussir\n" +
                "• Les quiz standalone sont également disponibles dans l'onglet 'Quizzes'\n\n" +
                "Bonne chance pour vos quiz ! 🎯";
    }

    private String generateHelpMessage() {
        return "🤖 Je suis votre assistant virtuel !\n\n" +
                "Voici ce que je peux faire pour vous :\n\n" +
                "• 📊 Voir votre progression dans vos cours\n" +
                "• 📚 Vous recommander des cours adaptés\n" +
                "• 📖 Vous informer sur vos cours\n" +
                "• 📝 Vous expliquer le système de quiz\n" +
                "• 💡 Répondre à vos questions\n\n" +
                "N'hésitez pas à me poser des questions ! Je suis là pour vous aider. 😊";
    }

    private String generateDefaultResponse(User student, List<Enrollment> enrollments) {
        StringBuilder response = new StringBuilder();
        response.append("Je comprends votre question. Laissez-moi vous aider ! 😊\n\n");
        
        if (enrollments.isEmpty()) {
            response.append("Je remarque que vous n'êtes pas encore inscrit à un cours.\n");
            response.append("Souhaitez-vous que je vous recommande des cours ?\n\n");
        } else {
            long completedCount = enrollments.stream().filter(Enrollment::isCompleted).count();
            if (completedCount < enrollments.size()) {
                response.append("Vous avez ").append(enrollments.size() - completedCount)
                        .append(" cours en cours. Continuez vos efforts ! 💪\n\n");
            }
        }
        
        response.append("Voici quelques suggestions :\n");
        response.append("• Demandez-moi votre progression\n");
        response.append("• Demandez des recommandations de cours\n");
        response.append("• Posez-moi des questions sur vos cours\n");
        response.append("• Demandez de l'aide sur le système\n\n");
        response.append("Comment puis-je vous aider ?");
        
        return response.toString();
    }
}

