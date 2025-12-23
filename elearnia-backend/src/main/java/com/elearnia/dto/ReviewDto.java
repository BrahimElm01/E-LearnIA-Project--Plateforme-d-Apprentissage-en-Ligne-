package com.elearnia.dto;

import com.elearnia.entities.Review;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ReviewDto {
    private Long id;
    private String studentName;
    private int rating;
    private String comment;
    private Review.ReviewStatus status;
    private LocalDateTime createdAt;

    public static ReviewDto fromEntity(Review review) {
        return new ReviewDto(
                review.getId(),
                review.getStudent().getFullName(),
                review.getRating(),
                review.getComment(),
                review.getStatus(),
                review.getCreatedAt()
        );
    }
}











