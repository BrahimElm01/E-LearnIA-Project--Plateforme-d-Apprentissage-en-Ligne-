package com.elearnia.repository;

import com.elearnia.entities.Review;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface ReviewRepository extends JpaRepository<Review, Long> {
    List<Review> findByCourseId(Long courseId);
    List<Review> findByCourseIdAndStatus(Long courseId, Review.ReviewStatus status);
    List<Review> findByStudentIdAndCourseId(Long studentId, Long courseId);
    
    // Supprimer toutes les reviews d'un cours
    @Modifying
    @Query("DELETE FROM Review r WHERE r.course.id = :courseId")
    void deleteByCourseId(@Param("courseId") Long courseId);
}



