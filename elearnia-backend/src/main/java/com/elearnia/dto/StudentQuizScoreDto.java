package com.elearnia.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class StudentQuizScoreDto {
    private Long attemptId;
    private Long studentId;
    private String studentName;
    private String studentEmail;
    private double score;
    private boolean passed;
    private int attemptNumber;
    private LocalDateTime completedAt;
}










