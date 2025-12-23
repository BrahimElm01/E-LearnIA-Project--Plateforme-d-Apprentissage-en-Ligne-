package com.elearnia.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class QuizResultDto {
    private double score; // Score en pourcentage
    private boolean passed; // true si score >= passingScore
    private int attemptNumber; // Numéro de la tentative
    private int remainingAttempts; // Tentatives restantes
    private boolean courseCompleted; // true si le cours est maintenant complété
}











