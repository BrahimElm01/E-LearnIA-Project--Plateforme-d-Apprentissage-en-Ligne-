package com.elearnia.dto;

import lombok.Data;

@Data
public class UpdateCourseRequest {
    private String title;
    private String description;
    private String imageUrl;
    private Boolean published;
}


