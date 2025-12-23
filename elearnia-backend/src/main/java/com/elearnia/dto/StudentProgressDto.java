package com.elearnia.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class StudentProgressDto {
    private Long studentId; // ID de l'étudiant pour permettre la réinitialisation des tentatives
    private String fullName;
    private String email;
    private double progress;
    private boolean completed;
    private Double rating;
}
