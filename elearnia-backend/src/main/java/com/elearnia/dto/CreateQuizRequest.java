package com.elearnia.dto;

import com.elearnia.entities.QuizLevel;
import lombok.Data;

import java.util.List;

@Data
public class CreateQuizRequest {
    private String title;
    private String description;
    private Integer passingScore; // Optionnel, par défaut 75
    private Integer maxAttempts; // Optionnel, par défaut 3
    private QuizLevel level; // Niveau du quiz (BEGINNER, INTERMEDIATE, ADVANCED)
    private Long courseId; // Optionnel : null pour quiz standalone
    private List<CreateQuestionRequest> questions;
}


