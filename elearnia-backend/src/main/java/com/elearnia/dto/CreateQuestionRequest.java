package com.elearnia.dto;

import lombok.Data;

import java.util.List;

@Data
public class CreateQuestionRequest {
    private String text;
    private String correctAnswer; // La réponse correcte
    private List<String> options; // Les options de réponse
    private Integer points; // Optionnel, par défaut 1
}











