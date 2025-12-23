package com.elearnia.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class GeneratedQuizDto {
    private String title;
    private String description;
    private List<GeneratedQuestionDto> questions;
}


