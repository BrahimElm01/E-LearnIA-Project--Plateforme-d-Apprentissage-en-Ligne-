package com.elearnia.dto;

import com.elearnia.entities.QuizLevel;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class QuizDto {
    private Long id;
    private String title;
    private String description;
    private int passingScore;
    private int maxAttempts;
    private int remainingAttempts; // Tentatives restantes pour l'étudiant
    private QuizLevel level; // Niveau du quiz
    private Long courseId; // ID du cours si lié à un cours, null sinon
    private List<QuestionDto> questions;
}

