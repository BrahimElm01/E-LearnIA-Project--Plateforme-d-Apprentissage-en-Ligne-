package com.elearnia.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class QuestionDto {
    private Long id;
    private String text;
    private List<String> options;
    private int points;
    // Note: on ne renvoie PAS la correctAnswer au client
}










