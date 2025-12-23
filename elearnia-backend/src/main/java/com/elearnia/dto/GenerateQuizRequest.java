package com.elearnia.dto;

import com.elearnia.entities.QuizLevel;
import lombok.Data;

@Data
public class GenerateQuizRequest {
    private String topic; // Sujet du quiz (ex: "Spring Boot", "Flutter", etc.)
    private QuizLevel difficulty; // Niveau de difficulté (BEGINNER, INTERMEDIATE, ADVANCED)
    private Integer numberOfQuestions; // Optionnel : nombre de questions (par défaut selon le niveau)
}









