package com.elearnia.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class GeneratedCourseDto {
    private String title; // Titre du cours généré
    private String description; // Description complète
    private String summary; // Résumé du cours
    private String imageUrl; // URL de la miniature générée
    private List<String> objectives; // Objectifs d'apprentissage
    private List<GeneratedLessonDto> lessons; // Plan du cours (leçons)
    private GeneratedQuizDto quiz; // Quiz généré
}

