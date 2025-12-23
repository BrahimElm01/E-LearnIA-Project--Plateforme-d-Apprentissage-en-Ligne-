package com.elearnia.controller;

import com.elearnia.dto.CreateReviewRequest;
import com.elearnia.dto.EnrollmentResponseDto;
import com.elearnia.dto.ReviewDto;
import com.elearnia.dto.StudentCourseDto;
import com.elearnia.dto.UpdateCourseProgressRequest;
import com.elearnia.entities.Course;
import com.elearnia.entities.Enrollment;
import com.elearnia.entities.Lesson;
import com.elearnia.entities.Quiz;
import com.elearnia.entities.Review;
import com.elearnia.model.User;
import com.elearnia.repository.CourseRepository;
import com.elearnia.repository.EnrollmentRepository;
import com.elearnia.repository.LessonRepository;
import com.elearnia.repository.QuizAttemptRepository;
import com.elearnia.repository.QuizRepository;
import com.elearnia.repository.ReviewRepository;
import com.elearnia.repository.UserRepository;
import com.elearnia.security.JwtService;
import com.elearnia.service.NotificationService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/student")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class StudentCourseController {

    private final CourseRepository courseRepository;
    private final EnrollmentRepository enrollmentRepository;
    private final ReviewRepository reviewRepository;
    private final UserRepository userRepository;
    private final QuizRepository quizRepository;
    private final QuizAttemptRepository quizAttemptRepository;
    private final LessonRepository lessonRepository;
    private final JwtService jwtService;
    private final NotificationService notificationService;

    // ============================================================
    // Helper : récupérer l'utilisateur courant à partir du header
    // ============================================================

    private User getUserFromBearer(String bearer) {
        // Vérifier que le header existe
        if (bearer == null || bearer.trim().isEmpty()) {
            throw new RuntimeException("Authorization header manquant");
        }

        // Accepte "Bearer xxx" ou "bearer xxx"
        String[] parts = bearer.trim().split("\\s+");   // <== syntaxe Java correcte
        if (parts.length != 2) {
            throw new RuntimeException("Authorization header invalide");
        }

        String token = parts[1].trim();
        String email = jwtService.extractUsername(token);

        return userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("Utilisateur non trouvé"));
    }

    // ============================================================
    // 1. Liste de TOUS les cours disponibles avec progression (home étudiant)
    // GET /student/courses
    // ============================================================

    @GetMapping("/courses")
    public List<StudentCourseDto> listAllCourses(
            @RequestHeader("Authorization") String bearer
    ) {
        User student = getUserFromBearer(bearer);
        List<Course> allCourses = courseRepository.findAll();
        
        return allCourses.stream().map(course -> {
            // Chercher l'enrollment de l'étudiant pour ce cours
            Enrollment enrollment = enrollmentRepository
                    .findByStudentIdAndCourseId(student.getId(), course.getId())
                    .orElse(null);
            
            double progress = 0.0;
            boolean completed = false;
            
            if (enrollment != null) {
                progress = enrollment.getProgress();
                completed = enrollment.isCompleted();
            }
            
            return new StudentCourseDto(
                    course.getId(),
                    course.getTitle(),
                    course.getDescription(),
                    course.getTeacher().getFullName(),
                    course.getImageUrl(),
                    progress,
                    completed
            );
        }).collect(Collectors.toList());
    }

    // ============================================================
    // 2. Récupérer les détails d'un cours spécifique
    // GET /student/courses/{courseId}
    // ============================================================

    @GetMapping("/courses/{courseId}")
    public ResponseEntity<Course> getCourseDetails(
            @RequestHeader("Authorization") String bearer,
            @PathVariable("courseId") Long courseId
    ) {
        User student = getUserFromBearer(bearer);
        
        Course course = courseRepository.findByIdWithTeacher(courseId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Cours introuvable"
                ));
        
        // Vérifier que le cours est publié
        if (!course.isPublished()) {
            // Vérifier si l'étudiant est inscrit
            boolean isEnrolled = enrollmentRepository
                    .findByStudentIdAndCourseId(student.getId(), courseId)
                    .isPresent();
            
            if (!isEnrolled) {
                throw new ResponseStatusException(
                        HttpStatus.FORBIDDEN,
                        "Ce cours n'est pas disponible"
                );
            }
        }
        
        return ResponseEntity.ok(course);
    }

    // ============================================================
    // 3. L'étudiant s'inscrit à un cours
    // POST /student/courses/{courseId}/enroll
    // ============================================================

    @PostMapping("/courses/{courseId}/enroll")
    public ResponseEntity<Enrollment> enrollToCourse(
            @RequestHeader("Authorization") String bearer,
            @PathVariable("courseId") Long courseId
    ) {
        User student = getUserFromBearer(bearer);

        Course course = courseRepository.findById(courseId)
                .orElseThrow(() -> new RuntimeException("Cours introuvable"));

        // Vérifier s'il est déjà inscrit
        Enrollment existing = enrollmentRepository
                .findByStudentIdAndCourseId(student.getId(), courseId)
                .orElse(null);

        if (existing != null) {
            // Déjà inscrit → on renvoie l'inscription existante
            return ResponseEntity.ok(existing);
        }

        Enrollment enrollment = new Enrollment();
        enrollment.setStudent(student);
        enrollment.setCourse(course);
        enrollment.setProgress(0.0);
        enrollment.setCompleted(false);
        enrollment.setRating(null);

        Enrollment saved = enrollmentRepository.save(enrollment);
        
        // Envoyer une notification au professeur
        try {
            notificationService.sendEnrollmentNotification(
                    course.getTeacher(),
                    student,
                    course
            );
        } catch (Exception e) {
            // Ne pas faire échouer l'inscription si la notification échoue
            System.err.println("Erreur lors de l'envoi de la notification: " + e.getMessage());
        }
        
        return ResponseEntity.ok(saved);
    }

    // ============================================================
    // 3. Liste "My Courses" pour l’étudiant connecté
    // GET /student/courses/my
    // ============================================================

    @GetMapping("/courses/my")
    public List<Enrollment> myCourses(
            @RequestHeader("Authorization") String bearer
    ) {
        User student = getUserFromBearer(bearer);
        return enrollmentRepository.findByStudentId(student.getId());
    }

    // ============================================================
    // 4. Mise à jour de la progression / note d’un cours
    // PUT /student/courses/{courseId}/progress
    // ============================================================

    @PutMapping("/courses/{courseId}/progress")
    public ResponseEntity<EnrollmentResponseDto> updateProgress(
            @RequestHeader("Authorization") String bearer,
            @PathVariable("courseId") Long courseId,
            @RequestBody UpdateCourseProgressRequest request
    ) {
        User student = getUserFromBearer(bearer);

        Enrollment enrollment = enrollmentRepository
                .findByStudentIdAndCourseId(student.getId(), courseId)
                .orElseThrow(() -> new RuntimeException("Inscription non trouvée"));

        boolean wasCompleted = enrollment.isCompleted();
        
        if (request.getProgress() != null) {
            // Limiter la progression à 100% maximum
            double progress = Math.min(100.0, Math.max(0.0, request.getProgress()));
            enrollment.setProgress(progress);
        }
        
        // Vérifier automatiquement si le cours est complété (tous les quizzes réussis)
        boolean allQuizzesPassed = checkAllQuizzesPassed(student.getId(), courseId);
        if (allQuizzesPassed) {
            enrollment.setCompleted(true);
        } else if (request.getCompleted() != null) {
            enrollment.setCompleted(request.getCompleted());
        }
        
        if (request.getRating() != null) {
            enrollment.setRating(request.getRating());
        }

        Enrollment saved = enrollmentRepository.save(enrollment);
        
        // Envoyer une notification au professeur si le cours vient d'être complété
        if (request.getCompleted() != null && request.getCompleted() && !wasCompleted) {
            try {
                notificationService.sendCompletionNotification(
                        saved.getCourse().getTeacher(),
                        student,
                        saved.getCourse()
                );
            } catch (Exception e) {
                // Ne pas faire échouer la mise à jour si la notification échoue
                System.err.println("Erreur lors de l'envoi de la notification: " + e.getMessage());
            }
        }
        
        // Retourner un DTO au lieu de l'entité pour éviter les problèmes de proxy Hibernate
        EnrollmentResponseDto response = new EnrollmentResponseDto(
                saved.getId(),
                saved.getProgress(),
                saved.isCompleted(),
                saved.getRating()
        );
        
        return ResponseEntity.ok(response);
    }

    // Méthode pour vérifier si tous les quizzes d'un cours sont complétés avec succès
    private boolean checkAllQuizzesPassed(Long studentId, Long courseId) {
        // Récupérer toutes les leçons du cours
        List<Lesson> lessons = lessonRepository.findByCourseIdOrderByOrderIndexAsc(courseId);
        
        if (lessons.isEmpty()) {
            return false; // Pas de leçons = pas de quizzes à compléter
        }
        
        // Vérifier que chaque leçon a un quiz et que l'étudiant l'a réussi
        for (Lesson lesson : lessons) {
            Quiz quiz = quizRepository.findByLessonId(lesson.getId()).orElse(null);
            if (quiz == null) {
                continue; // Si une leçon n'a pas de quiz, on continue
            }
            
            // Vérifier si l'étudiant a réussi ce quiz
            boolean passed = quizAttemptRepository.hasPassedQuiz(studentId, quiz.getId());
            if (!passed) {
                return false; // Au moins un quiz n'est pas réussi
            }
        }
        
        return true; // Tous les quizzes sont réussis
    }

    // ============================================================
    // 5. Ajouter un review pour un cours
    // POST /student/courses/{courseId}/reviews
    // ============================================================

    @PostMapping("/courses/{courseId}/reviews")
    public ResponseEntity<ReviewDto> addReview(
            @RequestHeader("Authorization") String bearer,
            @PathVariable("courseId") Long courseId,
            @RequestBody CreateReviewRequest request
    ) {
        User student = getUserFromBearer(bearer);

        Course course = courseRepository.findById(courseId)
                .orElseThrow(() -> new RuntimeException("Cours introuvable"));

        // Vérifier que l'étudiant est inscrit au cours
        enrollmentRepository
                .findByStudentIdAndCourseId(student.getId(), courseId)
                .orElseThrow(() -> new RuntimeException("Vous devez être inscrit au cours pour ajouter un avis"));

        // Permettre plusieurs avis par étudiant
        Review review = Review.builder()
                .student(student)
                .course(course)
                .rating(request.getRating())
                .comment(request.getComment())
                .status(Review.ReviewStatus.PENDING)
                .build();

        Review saved = reviewRepository.save(review);
        return ResponseEntity.ok(ReviewDto.fromEntity(saved));
    }

    // ============================================================
    // 6. Obtenir les reviews approuvés d'un cours
    // GET /student/courses/{courseId}/reviews
    // ============================================================

    @GetMapping("/courses/{courseId}/reviews")
    public List<ReviewDto> getApprovedReviews(@PathVariable("courseId") Long courseId) {
        List<Review> reviews = reviewRepository.findByCourseIdAndStatus(
                courseId,
                Review.ReviewStatus.APPROVED
        );
        return reviews.stream()
                .map(ReviewDto::fromEntity)
                .collect(Collectors.toList());
    }
}
