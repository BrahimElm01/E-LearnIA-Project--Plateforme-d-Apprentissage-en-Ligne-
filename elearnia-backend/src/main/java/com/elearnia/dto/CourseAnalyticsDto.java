package com.elearnia.dto;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class CourseAnalyticsDto {
    private long totalStudents;
    private long activeCourses;
    private double avgRating;
}
