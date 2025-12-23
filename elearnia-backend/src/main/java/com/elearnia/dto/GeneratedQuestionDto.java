package com.elearnia.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class GeneratedQuestionDto {
    private String text;
    private List<String> options;
    private String correctAnswer;
    private Integer points;
}


