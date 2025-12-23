package com.elearnia.dto;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class UpdateCourseProgressRequest {

    private Double progress;    // 0.0 à 100.0
    private Boolean completed;  // true / false
    private Double rating;      // 0.0 à 5.0 par ex.
}
