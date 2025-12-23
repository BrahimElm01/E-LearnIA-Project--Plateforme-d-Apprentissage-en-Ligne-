package com.elearnia.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class AllQuizzesScoresDto {
    private Long quizId;
    private String quizTitle;
    private String level;
    private String courseTitle; // "Quiz standalone" si pas lié à un cours
    private List<StudentQuizScoreDto> scores;
}










