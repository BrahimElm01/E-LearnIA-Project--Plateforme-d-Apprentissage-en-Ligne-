package com.elearnia.repository;

import com.elearnia.entities.Enrollment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface EnrollmentRepository extends JpaRepository<Enrollment, Long> {

    // ====== EXISTANT : côté cours / prof ======

    List<Enrollment> findByCourseId(Long courseId);

    @Query(
            "SELECT COUNT(DISTINCT e.student.id) " +
                    "FROM Enrollment e " +
                    "WHERE e.course.teacher.id = :teacherId"
    )
    long countDistinctStudentByTeacherId(@Param("teacherId") Long teacherId);

    @Query(
            "SELECT COALESCE(AVG(e.rating), 0) " +
                    "FROM Enrollment e " +
                    "WHERE e.course.teacher.id = :teacherId"
    )
    double avgRatingByTeacherId(@Param("teacherId") Long teacherId);

    // ====== NOUVEAU : côté étudiant ======

    // Tous les cours où l’étudiant est inscrit
    List<Enrollment> findByStudentId(Long studentId);

    // Une seule inscription pour (student, course)
    Optional<Enrollment> findByStudentIdAndCourseId(Long studentId, Long courseId);
    
    // Supprimer toutes les inscriptions d'un cours
    @Modifying
    @Query("DELETE FROM Enrollment e WHERE e.course.id = :courseId")
    void deleteByCourseId(@Param("courseId") Long courseId);
}
