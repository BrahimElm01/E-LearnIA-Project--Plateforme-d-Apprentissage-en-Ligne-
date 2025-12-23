package com.elearnia.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class CreateLessonRequest {
    @NotBlank
    private String title;

    private String description;

    private String videoUrl; // Optionnel - peut être null ou vide pour les leçons sans vidéo

    private Integer duration; // en minutes

    @NotNull
    private Integer orderIndex;
}


