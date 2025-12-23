package com.elearnia.controller;

import com.elearnia.dto.CreateLessonRequest;
import com.elearnia.entities.Course;
import com.elearnia.entities.Lesson;
import com.elearnia.entities.Quiz;
import com.elearnia.model.User;
import com.elearnia.repository.CourseRepository;
import com.elearnia.repository.LessonRepository;
import com.elearnia.repository.QuizRepository;
import com.elearnia.service.AuthService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/teacher/courses/{courseId}/lessons")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class LessonController {

    private final LessonRepository lessonRepository;
    private final CourseRepository courseRepository;
    private final QuizRepository quizRepository;
    private final AuthService authService;

    private User getTeacherFromBearer(String bearer) {
        if (bearer == null || bearer.trim().isEmpty()) {
            throw new RuntimeException("Authorization header manquant");
        }
        String token = bearer.replace("Bearer ", "").trim();
        if (token.isEmpty()) {
            throw new RuntimeException("Token manquant");
        }
        return authService.getCurrentUserFromToken(token);
    }

    // Créer une leçon pour un cours
    @PostMapping
    public ResponseEntity<Lesson> createLesson(
            @RequestHeader("Authorization") String bearer,
            @PathVariable("courseId") Long courseId,
            @Valid @RequestBody CreateLessonRequest request
    ) {
        User teacher = getTeacherFromBearer(bearer);
        
        // Vérifier que l'utilisateur est un professeur
        if (teacher.getRole() != com.elearnia.model.Role.TEACHER && 
            teacher.getRole() != com.elearnia.model.Role.ADMIN) {
            throw new RuntimeException("Seuls les professeurs peuvent créer des leçons");
        }
        
        Course course = courseRepository.findById(courseId)
                .orElseThrow(() -> new RuntimeException("Cours introuvable"));

        // Vérifier que le cours appartient au professeur
        if (!course.getTeacher().getId().equals(teacher.getId())) {
            throw new RuntimeException("Vous n'êtes pas autorisé à modifier ce cours");
        }

        // Normaliser l'URL YouTube si c'est une URL YouTube, sinon null si vide
        String normalizedVideoUrl = request.getVideoUrl();
        if (normalizedVideoUrl != null && !normalizedVideoUrl.trim().isEmpty()) {
            normalizedVideoUrl = com.elearnia.util.YouTubeUrlNormalizer.normalize(normalizedVideoUrl);
        } else {
            normalizedVideoUrl = null; // Pas de vidéo
        }
        
        Lesson lesson = Lesson.builder()
                .title(request.getTitle())
                .description(request.getDescription())
                .videoUrl(normalizedVideoUrl)
                .duration(request.getDuration())
                .orderIndex(request.getOrderIndex())
                .course(course)
                .build();

        Lesson saved = lessonRepository.save(lesson);
        return ResponseEntity.ok(saved);
    }

    // Récupérer toutes les leçons d'un cours (pour le prof)
    @GetMapping
    public ResponseEntity<List<Lesson>> getLessons(
            @RequestHeader("Authorization") String bearer,
            @PathVariable("courseId") Long courseId
    ) {
        User teacher = getTeacherFromBearer(bearer);
        
        // Vérifier que l'utilisateur est un professeur
        if (teacher.getRole() != com.elearnia.model.Role.TEACHER && 
            teacher.getRole() != com.elearnia.model.Role.ADMIN) {
            throw new RuntimeException("Seuls les professeurs peuvent accéder à cette ressource");
        }
        
        Course course = courseRepository.findById(courseId)
                .orElseThrow(() -> new RuntimeException("Cours introuvable"));

        // Vérifier que le cours appartient au professeur
        if (!course.getTeacher().getId().equals(teacher.getId())) {
            throw new RuntimeException("Vous n'êtes pas autorisé à voir ce cours");
        }

        List<Lesson> lessons = lessonRepository.findByCourseIdOrderByOrderIndexAsc(courseId);
        return ResponseEntity.ok(lessons);
    }

    // Modifier une leçon
    @PutMapping("/{lessonId}")
    public ResponseEntity<Lesson> updateLesson(
            @RequestHeader("Authorization") String bearer,
            @PathVariable("courseId") Long courseId,
            @PathVariable("lessonId") Long lessonId,
            @Valid @RequestBody CreateLessonRequest request
    ) {
        User teacher = getTeacherFromBearer(bearer);
        
        // Vérifier que l'utilisateur est un professeur
        if (teacher.getRole() != com.elearnia.model.Role.TEACHER && 
            teacher.getRole() != com.elearnia.model.Role.ADMIN) {
            throw new RuntimeException("Seuls les professeurs peuvent modifier des leçons");
        }
        
        Course course = courseRepository.findById(courseId)
                .orElseThrow(() -> new RuntimeException("Cours introuvable"));

        // Vérifier que le cours appartient au professeur
        if (!course.getTeacher().getId().equals(teacher.getId())) {
            throw new RuntimeException("Vous n'êtes pas autorisé à modifier ce cours");
        }

        Lesson lesson = lessonRepository.findById(lessonId)
                .orElseThrow(() -> new RuntimeException("Leçon introuvable"));

        if (!lesson.getCourse().getId().equals(courseId)) {
            throw new RuntimeException("La leçon n'appartient pas à ce cours");
        }

        // Mettre à jour les champs
        lesson.setTitle(request.getTitle());
        lesson.setDescription(request.getDescription());
        
        // Normaliser l'URL YouTube si c'est une URL YouTube, sinon null si vide
        String normalizedVideoUrl = request.getVideoUrl();
        if (normalizedVideoUrl != null && !normalizedVideoUrl.trim().isEmpty()) {
            normalizedVideoUrl = com.elearnia.util.YouTubeUrlNormalizer.normalize(normalizedVideoUrl);
            lesson.setVideoUrl(normalizedVideoUrl);
        } else {
            // Si pas de vidéo, définir à null
            lesson.setVideoUrl(null);
        }
        if (request.getDuration() != null) {
            lesson.setDuration(request.getDuration());
        }
        if (request.getOrderIndex() != null) {
            lesson.setOrderIndex(request.getOrderIndex());
        }

        Lesson saved = lessonRepository.save(lesson);
        return ResponseEntity.ok(saved);
    }

    // Supprimer une leçon
    @DeleteMapping("/{lessonId}")
    public ResponseEntity<Void> deleteLesson(
            @RequestHeader("Authorization") String bearer,
            @PathVariable("courseId") Long courseId,
            @PathVariable("lessonId") Long lessonId
    ) {
        User teacher = getTeacherFromBearer(bearer);
        Course course = courseRepository.findById(courseId)
                .orElseThrow(() -> new RuntimeException("Cours introuvable"));

        if (!course.getTeacher().getId().equals(teacher.getId())) {
            throw new RuntimeException("Vous n'êtes pas autorisé à modifier ce cours");
        }

        Lesson lesson = lessonRepository.findById(lessonId)
                .orElseThrow(() -> new RuntimeException("Leçon introuvable"));

        if (!lesson.getCourse().getId().equals(courseId)) {
            throw new RuntimeException("La leçon n'appartient pas à ce cours");
        }

        lessonRepository.delete(lesson);
        return ResponseEntity.ok().build();
    }

    // Associer un quiz existant à une leçon
    @PutMapping("/{lessonId}/quiz/{quizId}")
    public ResponseEntity<Lesson> assignQuizToLesson(
            @RequestHeader("Authorization") String bearer,
            @PathVariable("courseId") Long courseId,
            @PathVariable("lessonId") Long lessonId,
            @PathVariable("quizId") Long quizId
    ) {
        User teacher = getTeacherFromBearer(bearer);
        
        if (teacher.getRole() != com.elearnia.model.Role.TEACHER && 
            teacher.getRole() != com.elearnia.model.Role.ADMIN) {
            throw new RuntimeException("Seuls les professeurs peuvent modifier des leçons");
        }
        
        Course course = courseRepository.findById(courseId)
                .orElseThrow(() -> new RuntimeException("Cours introuvable"));

        if (!course.getTeacher().getId().equals(teacher.getId())) {
            throw new RuntimeException("Vous n'êtes pas autorisé à modifier ce cours");
        }

        Lesson lesson = lessonRepository.findById(lessonId)
                .orElseThrow(() -> new RuntimeException("Leçon introuvable"));

        if (!lesson.getCourse().getId().equals(courseId)) {
            throw new RuntimeException("La leçon n'appartient pas à ce cours");
        }

        Quiz quiz = quizRepository.findById(quizId)
                .orElseThrow(() -> new RuntimeException("Quiz introuvable"));

        // Vérifier que le quiz appartient au même cours ou est standalone
        if (quiz.getCourse() != null && !quiz.getCourse().getId().equals(courseId)) {
            throw new RuntimeException("Le quiz n'appartient pas à ce cours");
        }

        // Associer le quiz à la leçon
        quiz.setLesson(lesson);
        quiz.setCourse(course); // S'assurer que le quiz est lié au cours aussi
        quizRepository.save(quiz);

        return ResponseEntity.ok(lesson);
    }

    // Retirer le quiz d'une leçon
    @DeleteMapping("/{lessonId}/quiz")
    public ResponseEntity<Void> removeQuizFromLesson(
            @RequestHeader("Authorization") String bearer,
            @PathVariable("courseId") Long courseId,
            @PathVariable("lessonId") Long lessonId
    ) {
        User teacher = getTeacherFromBearer(bearer);
        
        if (teacher.getRole() != com.elearnia.model.Role.TEACHER && 
            teacher.getRole() != com.elearnia.model.Role.ADMIN) {
            throw new RuntimeException("Seuls les professeurs peuvent modifier des leçons");
        }
        
        Course course = courseRepository.findById(courseId)
                .orElseThrow(() -> new RuntimeException("Cours introuvable"));

        if (!course.getTeacher().getId().equals(teacher.getId())) {
            throw new RuntimeException("Vous n'êtes pas autorisé à modifier ce cours");
        }

        Lesson lesson = lessonRepository.findById(lessonId)
                .orElseThrow(() -> new RuntimeException("Leçon introuvable"));

        if (!lesson.getCourse().getId().equals(courseId)) {
            throw new RuntimeException("La leçon n'appartient pas à ce cours");
        }

        // Retirer le quiz de la leçon
        Quiz quiz = quizRepository.findByLessonId(lessonId).orElse(null);
        if (quiz != null) {
            quiz.setLesson(null);
            quizRepository.save(quiz);
        }

        return ResponseEntity.ok().build();
    }

    // Récupérer le quiz d'une leçon
    @GetMapping("/{lessonId}/quiz")
    public ResponseEntity<Quiz> getLessonQuiz(
            @RequestHeader("Authorization") String bearer,
            @PathVariable("courseId") Long courseId,
            @PathVariable("lessonId") Long lessonId
    ) {
        User teacher = getTeacherFromBearer(bearer);
        
        if (teacher.getRole() != com.elearnia.model.Role.TEACHER && 
            teacher.getRole() != com.elearnia.model.Role.ADMIN) {
            throw new RuntimeException("Seuls les professeurs peuvent accéder à cette ressource");
        }
        
        Course course = courseRepository.findById(courseId)
                .orElseThrow(() -> new RuntimeException("Cours introuvable"));

        if (!course.getTeacher().getId().equals(teacher.getId())) {
            throw new RuntimeException("Vous n'êtes pas autorisé à voir ce cours");
        }

        Lesson lesson = lessonRepository.findById(lessonId)
                .orElseThrow(() -> new RuntimeException("Leçon introuvable"));

        if (!lesson.getCourse().getId().equals(courseId)) {
            throw new RuntimeException("La leçon n'appartient pas à ce cours");
        }

        Quiz quiz = quizRepository.findByLessonId(lessonId)
                .orElse(null);

        if (quiz == null) {
            return ResponseEntity.noContent().build();
        }

        return ResponseEntity.ok(quiz);
    }
}

