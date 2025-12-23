package com.elearnia.repository;

import com.elearnia.entities.Quiz;
import com.elearnia.entities.QuizLevel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface QuizRepository extends JpaRepository<Quiz, Long> {
    Optional<Quiz> findByCourseId(Long courseId);
    
    // Récupérer tous les quizzes standalone (sans cours) avec les questions chargées
    @Query("SELECT DISTINCT q FROM Quiz q LEFT JOIN FETCH q.questions WHERE q.course IS NULL")
    List<Quiz> findByCourseIdIsNull();
    
    // Récupérer les quizzes par niveau
    @Query("SELECT q FROM Quiz q WHERE q.level = :level")
    List<Quiz> findByLevel(@Param("level") QuizLevel level);
    
    // Récupérer les quizzes standalone par niveau avec les questions chargées
    @Query("SELECT DISTINCT q FROM Quiz q LEFT JOIN FETCH q.questions WHERE q.course IS NULL AND q.level = :level")
    List<Quiz> findByCourseIdIsNullAndLevel(@Param("level") QuizLevel level);
    
    // Récupérer tous les quizzes (standalone et liés à des cours)
    List<Quiz> findAll();
    
    // Récupérer tous les quizzes d'un cours
    @Query("SELECT q FROM Quiz q WHERE q.course.id = :courseId")
    List<Quiz> findAllByCourseId(@Param("courseId") Long courseId);
    
    // Supprimer tous les quizzes d'un cours
    @Modifying
    @Query("DELETE FROM Quiz q WHERE q.course.id = :courseId")
    void deleteByCourseId(@Param("courseId") Long courseId);
    
    // Récupérer le quiz d'une leçon
    Optional<Quiz> findByLessonId(Long lessonId);
}


