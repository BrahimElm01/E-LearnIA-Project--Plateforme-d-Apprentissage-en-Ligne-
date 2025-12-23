package com.elearnia.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class QuizSummaryDto {
    private Long id;
    private String title;
    private String description;
    private int passingScore;
    private int maxAttempts;
    private int remainingAttempts;
    private String level; // BEGINNER, INTERMEDIATE, ADVANCED
    private int questionCount; // Nombre de questions
}










