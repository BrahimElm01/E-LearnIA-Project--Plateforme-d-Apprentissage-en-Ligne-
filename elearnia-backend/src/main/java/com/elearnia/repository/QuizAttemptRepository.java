package com.elearnia.repository;

import com.elearnia.entities.QuizAttempt;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface QuizAttemptRepository extends JpaRepository<QuizAttempt, Long> {
    List<QuizAttempt> findByUserIdAndQuizIdOrderByAttemptNumberDesc(Long userId, Long quizId);
    
    Optional<QuizAttempt> findTopByUserIdAndQuizIdOrderByAttemptNumberDesc(Long userId, Long quizId);
    
    int countByUserIdAndQuizId(Long userId, Long quizId);
    
    List<QuizAttempt> findByQuizIdOrderByCompletedAtDesc(Long quizId);
    
    // Supprimer toutes les tentatives d'un quiz
    @Modifying
    @Query("DELETE FROM QuizAttempt qa WHERE qa.quiz.id = :quizId")
    void deleteByQuizId(@Param("quizId") Long quizId);
    
    // Vérifier si l'étudiant a réussi un quiz (au moins une tentative réussie)
    @Query("SELECT COUNT(qa) > 0 FROM QuizAttempt qa WHERE qa.user.id = :userId AND qa.quiz.id = :quizId AND qa.passed = true")
    boolean hasPassedQuiz(@Param("userId") Long userId, @Param("quizId") Long quizId);
    
    // Récupérer tous les quizzes réussis par un étudiant pour un cours
    @Query("SELECT DISTINCT qa.quiz.id FROM QuizAttempt qa WHERE qa.user.id = :userId AND qa.quiz.course.id = :courseId AND qa.passed = true")
    List<Long> findPassedQuizIdsByCourse(@Param("userId") Long userId, @Param("courseId") Long courseId);
}


