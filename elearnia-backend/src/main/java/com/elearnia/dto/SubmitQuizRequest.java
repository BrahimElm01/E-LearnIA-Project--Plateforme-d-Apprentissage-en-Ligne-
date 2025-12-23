package com.elearnia.dto;

import lombok.Data;

import java.util.Map;

@Data
public class SubmitQuizRequest {
    // Map: questionId (String) -> answer (la réponse de l'étudiant)
    // Les clés sont des String car JSON convertit les nombres en String
    private Map<String, String> answers;
}

