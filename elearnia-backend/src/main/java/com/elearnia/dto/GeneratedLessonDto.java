package com.elearnia.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class GeneratedLessonDto {
    private String title;
    private String description;
    private Integer orderIndex;
    private Integer estimatedDuration; // en minutes
    private String videoUrl; // URL de la vidéo YouTube
}

