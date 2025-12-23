package com.elearnia.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class StudentCourseDto {
    private Long id;
    private String title;
    private String description;
    private String teacherName;
    private String imageUrl;
    private double progress; // 0..100
    private boolean completed;
}











