package com.elearnia.dto;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class EnrollmentResponseDto {
    private Long id;
    private double progress;
    private boolean completed;
    private Double rating;
}


