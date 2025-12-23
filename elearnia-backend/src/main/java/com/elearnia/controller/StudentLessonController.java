package com.elearnia.controller;

import com.elearnia.entities.Lesson;
import com.elearnia.entities.Quiz;
import com.elearnia.model.User;
import com.elearnia.repository.EnrollmentRepository;
import com.elearnia.repository.LessonRepository;
import com.elearnia.repository.QuizRepository;
import com.elearnia.repository.UserRepository;
import com.elearnia.security.JwtService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@RestController
@RequestMapping("/student/courses/{courseId}/lessons")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class StudentLessonController {

    private final LessonRepository lessonRepository;
    private final EnrollmentRepository enrollmentRepository;
    private final UserRepository userRepository;
    private final QuizRepository quizRepository;
    private final JwtService jwtService;

    private User getUserFromBearer(String bearer) {
        if (bearer == null || bearer.trim().isEmpty()) {
            throw new RuntimeException("Authorization header manquant");
        }
        String[] parts = bearer.trim().split("\\s+");
        if (parts.length != 2) {
            throw new RuntimeException("Authorization header invalide");
        }
        String token = parts[1].trim();
        String email = jwtService.extractUsername(token);
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("Utilisateur non trouvé"));
    }

    // Récupérer toutes les leçons d'un cours (pour l'étudiant)
    @GetMapping
    public ResponseEntity<List<Lesson>> getLessons(
            @RequestHeader("Authorization") String bearer,
            @PathVariable("courseId") Long courseId
    ) {
        User student = getUserFromBearer(bearer);

        // Vérifier que l'étudiant est inscrit au cours
        enrollmentRepository.findByStudentIdAndCourseId(student.getId(), courseId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.BAD_REQUEST,
                        "Vous n'êtes pas inscrit à ce cours"
                ));

        List<Lesson> lessons = lessonRepository.findByCourseIdOrderByOrderIndexAsc(courseId);
        return ResponseEntity.ok(lessons);
    }

    // Récupérer le quiz d'une leçon spécifique
    @GetMapping("/{lessonId}/quiz")
    public ResponseEntity<Quiz> getLessonQuiz(
            @RequestHeader("Authorization") String bearer,
            @PathVariable("courseId") Long courseId,
            @PathVariable("lessonId") Long lessonId
    ) {
        User student = getUserFromBearer(bearer);

        // Vérifier que l'étudiant est inscrit au cours
        enrollmentRepository.findByStudentIdAndCourseId(student.getId(), courseId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.FORBIDDEN,
                        "Vous n'êtes pas inscrit à ce cours"
                ));

        // Vérifier que la leçon existe et appartient au cours
        Lesson lesson = lessonRepository.findById(lessonId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Leçon introuvable"
                ));

        if (!lesson.getCourse().getId().equals(courseId)) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "La leçon n'appartient pas à ce cours"
            );
        }

        // Récupérer le quiz de la leçon
        Quiz quiz = quizRepository.findByLessonId(lessonId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Aucun quiz disponible pour cette leçon"
                ));

        return ResponseEntity.ok(quiz);
    }
}

