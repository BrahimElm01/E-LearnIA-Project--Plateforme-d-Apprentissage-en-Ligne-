package com.elearnia.controller;

import com.elearnia.dto.*;
import com.elearnia.entities.*;
import com.elearnia.model.User;
import com.elearnia.repository.*;
import com.elearnia.service.AuthService;
import com.elearnia.service.AICourseGeneratorService;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.http.HttpStatus;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/teacher/courses")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")   // pour tester tranquille
public class TeacherCourseController {

    private final CourseRepository courseRepository;
    private final EnrollmentRepository enrollmentRepository;
    private final LessonRepository lessonRepository;
    private final QuizRepository quizRepository;
    private final QuestionRepository questionRepository;
    private final ReviewRepository reviewRepository;
    private final QuizAttemptRepository quizAttemptRepository;
    private final AuthService authService;
    private final AICourseGeneratorService aiCourseGeneratorService;

    // ================== UTILITAIRE ==================

    /** Récupère le prof à partir du header Authorization: Bearer xxx */
    private User getTeacherFromBearer(String bearer) {
        if (bearer == null || bearer.trim().isEmpty()) {
            throw new ResponseStatusException(
                    HttpStatus.UNAUTHORIZED,
                    "Token d'authentification manquant"
            );
        }
        // Gérer le cas où le header contient "Bearer " ou non
        String token = bearer.startsWith("Bearer ") 
                ? bearer.substring(7).trim() 
                : bearer.trim();
        if (token.isEmpty()) {
            throw new ResponseStatusException(
                    HttpStatus.UNAUTHORIZED,
                    "Token d'authentification invalide"
            );
        }
        return authService.getCurrentUserFromToken(token);
    }

    // ================== CRÉATION DE COURS ==================

    @PostMapping
    public ResponseEntity<Course> createCourse(
            @RequestHeader("Authorization") String bearer,
            @RequestBody CreateCourseRequest request
    ) {
        User teacher = getTeacherFromBearer(bearer);

        Course course = Course.builder()
                .title(request.getTitle())
                .description(request.getDescription())
                .imageUrl(request.getImageUrl())
                .teacher(teacher)
                .build();

        Course saved = courseRepository.save(course);
        return ResponseEntity.ok(saved);
    }

    // ================== GÉNÉRATION DE COURS AVEC IA ==================

    @PostMapping("/generate")
    public ResponseEntity<GeneratedCourseDto> generateCourseWithAI(
            @RequestHeader("Authorization") String bearer,
            @RequestBody GenerateCourseRequest request
    ) {
        User teacher = getTeacherFromBearer(bearer);

        if (request.getIdea() == null || request.getIdea().trim().isEmpty()) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "L'idée du cours est requise"
            );
        }

        // Générer le cours avec l'IA
        GeneratedCourseDto generatedCourse = aiCourseGeneratorService.generateCourse(
                request.getIdea(),
                request.getLevel()
        );

        return ResponseEntity.ok(generatedCourse);
    }

    @PostMapping("/generate-and-create")
    @Transactional
    public ResponseEntity<Course> generateAndCreateCourse(
            @RequestHeader("Authorization") String bearer,
            @RequestBody GenerateCourseRequest request
    ) {
        User teacher = getTeacherFromBearer(bearer);

        if (request.getIdea() == null || request.getIdea().trim().isEmpty()) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "L'idée du cours est requise"
            );
        }

        // Générer le cours avec l'IA
        GeneratedCourseDto generated = aiCourseGeneratorService.generateCourse(
                request.getIdea(),
                request.getLevel()
        );

        // Créer le cours
        Course course = Course.builder()
                .title(generated.getTitle())
                .description(generated.getDescription())
                .imageUrl(generated.getImageUrl()) // Ajouter la miniature générée
                .teacher(teacher)
                .published(false) // Non publié par défaut, l'enseignant peut le publier après
                .build();

        Course savedCourse = courseRepository.save(course);

        // Créer les leçons
        if (generated.getLessons() != null) {
            for (GeneratedLessonDto lessonDto : generated.getLessons()) {
                Lesson lesson = Lesson.builder()
                        .title(lessonDto.getTitle())
                        .description(lessonDto.getDescription())
                        .orderIndex(lessonDto.getOrderIndex())
                        .duration(lessonDto.getEstimatedDuration())
                        .videoUrl(lessonDto.getVideoUrl() != null ? lessonDto.getVideoUrl() : "")
                        .course(savedCourse)
                        .build();
                lessonRepository.save(lesson);
            }
        }

        // Créer le quiz
        if (generated.getQuiz() != null && generated.getQuiz().getQuestions() != null && !generated.getQuiz().getQuestions().isEmpty()) {
            Quiz quiz = Quiz.builder()
                    .course(savedCourse)
                    .title(generated.getQuiz().getTitle())
                    .description(generated.getQuiz().getDescription())
                    .passingScore(75)
                    .maxAttempts(3)
                    .level(com.elearnia.entities.QuizLevel.BEGINNER)
                    .build();

            // Créer les questions
            List<Question> questions = generated.getQuiz().getQuestions().stream()
                    .map(qDto -> Question.builder()
                            .quiz(quiz)
                            .text(qDto.getText())
                            .correctAnswer(qDto.getCorrectAnswer())
                            .options(qDto.getOptions())
                            .points(qDto.getPoints() != null ? qDto.getPoints() : 1)
                            .build())
                    .collect(Collectors.toList());

            quiz.setQuestions(questions);
            quizRepository.save(quiz);
        }

        return ResponseEntity.ok(savedCourse);
    }

    // ================== MES COURS ==================

    @GetMapping("/my")
    public ResponseEntity<List<Course>> getMyCourses(
            @RequestHeader("Authorization") String bearer
    ) {
        User teacher = getTeacherFromBearer(bearer);
        List<Course> courses = courseRepository.findByTeacher(teacher);
        return ResponseEntity.ok(courses);
    }

    @GetMapping("/{courseId}")
    public ResponseEntity<Course> getCourseById(
            @RequestHeader("Authorization") String bearer,
            @PathVariable("courseId") Long courseId
    ) {
        User teacher = getTeacherFromBearer(bearer);
        Course course = courseRepository.findById(courseId)
                .orElseThrow(() -> new RuntimeException("Cours introuvable"));

        // Vérifier que le cours appartient au professeur
        if (!course.getTeacher().getId().equals(teacher.getId())) {
            throw new RuntimeException("Vous n'êtes pas autorisé à accéder à ce cours");
        }

        return ResponseEntity.ok(course);
    }

    // ================== MODIFICATION DE COURS ==================

    @PutMapping("/{courseId}")
    public ResponseEntity<Course> updateCourse(
            @RequestHeader("Authorization") String bearer,
            @PathVariable("courseId") Long courseId,
            @RequestBody UpdateCourseRequest request
    ) {
        User teacher = getTeacherFromBearer(bearer);
        Course course = courseRepository.findById(courseId)
                .orElseThrow(() -> new RuntimeException("Cours introuvable"));

        // Vérifier que le cours appartient au professeur
        if (!course.getTeacher().getId().equals(teacher.getId())) {
            throw new RuntimeException("Vous n'êtes pas autorisé à modifier ce cours");
        }

        // Mettre à jour les champs si fournis
        if (request.getTitle() != null && !request.getTitle().trim().isEmpty()) {
            course.setTitle(request.getTitle());
        }
        if (request.getDescription() != null && !request.getDescription().trim().isEmpty()) {
            course.setDescription(request.getDescription());
        }
        if (request.getImageUrl() != null) {
            course.setImageUrl(request.getImageUrl());
        }
        if (request.getPublished() != null) {
            course.setPublished(request.getPublished());
        }

        Course saved = courseRepository.save(course);
        return ResponseEntity.ok(saved);
    }

    // ================== SUPPRESSION DE COURS ==================

    @DeleteMapping("/{courseId}")
    @Transactional
    public ResponseEntity<Void> deleteCourse(
            @RequestHeader("Authorization") String bearer,
            @PathVariable("courseId") Long courseId
    ) {
        User teacher = getTeacherFromBearer(bearer);
        Course course = courseRepository.findById(courseId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Cours introuvable"
                ));

        // Vérifier que le cours appartient au professeur
        if (!course.getTeacher().getId().equals(teacher.getId())) {
            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN,
                    "Vous n'êtes pas autorisé à supprimer ce cours"
            );
        }

        // 1. Supprimer toutes les reviews associées au cours
        reviewRepository.deleteByCourseId(courseId);
        
        // 2. Supprimer toutes les tentatives de quiz associées aux quizzes du cours
        List<Quiz> quizzes = quizRepository.findAllByCourseId(courseId);
        for (Quiz quiz : quizzes) {
            // Supprimer d'abord toutes les tentatives de quiz
            quizAttemptRepository.deleteByQuizId(quiz.getId());
            // Supprimer toutes les questions du quiz
            questionRepository.deleteByQuizId(quiz.getId());
        }
        
        // 3. Supprimer tous les quizzes associés au cours
        quizRepository.deleteByCourseId(courseId);
        
        // 4. Supprimer manuellement les leçons associées
        lessonRepository.deleteByCourseId(courseId);
        
        // 5. Supprimer manuellement les inscriptions associées
        enrollmentRepository.deleteByCourseId(courseId);
        
        // 6. Enfin, supprimer le cours
        courseRepository.delete(course);
        
        return ResponseEntity.noContent().build();
    }

    // ============ PROGRESS DES ÉTUDIANTS POUR UN COURS ============

    @GetMapping("/{courseId}/students-progress")
    public ResponseEntity<List<StudentProgressDto>> studentProgress(
            @RequestHeader("Authorization") String bearer,
            @PathVariable("courseId") Long courseId
    ) {
        User teacher = getTeacherFromBearer(bearer);
        Course course = courseRepository.findById(courseId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Cours introuvable"
                ));

        // Vérifier que le cours appartient au professeur
        if (!course.getTeacher().getId().equals(teacher.getId())) {
            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN,
                    "Vous n'êtes pas autorisé à voir la progression de ce cours"
            );
        }

        List<Enrollment> enrollments = enrollmentRepository.findByCourseId(courseId);

        // ✅ StudentProgressDto(Long studentId, String fullName, String email, double progress, boolean completed, Double rating)
        List<StudentProgressDto> result = enrollments.stream()
                .map(e -> new StudentProgressDto(
                        e.getStudent().getId(),           // studentId
                        e.getStudent().getFullName(),     // fullName
                        e.getStudent().getEmail(),        // email
                        e.getProgress(),                  // progress
                        e.isCompleted(),                  // completed
                        e.getRating()                     // rating
                ))
                .collect(Collectors.toList());

        return ResponseEntity.ok(result);
    }

    // ================== GESTION DES QUIZZES ==================

    // Récupérer tous les quizzes du professeur (standalone, ceux de ses cours, et ceux de ses leçons)
    @GetMapping("/quizzes")
    public ResponseEntity<List<QuizDto>> getTeacherQuizzes(
            @RequestHeader("Authorization") String bearer
    ) {
        User teacher = getTeacherFromBearer(bearer);

        // Récupérer tous les quizzes standalone
        List<Quiz> standaloneQuizzes = quizRepository.findByCourseIdIsNull();

        // Récupérer tous les quizzes des cours du professeur (y compris ceux liés aux leçons)
        List<Course> teacherCourses = courseRepository.findByTeacher(teacher);
        List<Quiz> courseQuizzes = new ArrayList<>();
        for (Course course : teacherCourses) {
            List<Quiz> quizzes = quizRepository.findAllByCourseId(course.getId());
            courseQuizzes.addAll(quizzes);
        }

        // Combiner les deux listes
        List<Quiz> allQuizzes = new ArrayList<>();
        allQuizzes.addAll(standaloneQuizzes);
        allQuizzes.addAll(courseQuizzes);

        // Convertir en QuizDto avec courseId
        List<QuizDto> quizDtos = allQuizzes.stream()
                .map(quiz -> {
                    QuizDto dto = new QuizDto();
                    dto.setId(quiz.getId());
                    dto.setTitle(quiz.getTitle());
                    dto.setDescription(quiz.getDescription());
                    dto.setPassingScore(quiz.getPassingScore());
                    dto.setMaxAttempts(quiz.getMaxAttempts());
                    dto.setRemainingAttempts(quiz.getMaxAttempts()); // Par défaut, toutes les tentatives sont disponibles
                    dto.setLevel(quiz.getLevel());
                    // Inclure le courseId si le quiz est lié à un cours
                    dto.setCourseId(quiz.getCourse() != null ? quiz.getCourse().getId() : null);
                    // Convertir les questions en QuestionDto
                    if (quiz.getQuestions() != null) {
                        dto.setQuestions(quiz.getQuestions().stream()
                                .map(q -> new QuestionDto(
                                        q.getId(),
                                        q.getText(),
                                        q.getOptions(),
                                        q.getPoints()
                                ))
                                .collect(Collectors.toList()));
                    } else {
                        dto.setQuestions(new ArrayList<>());
                    }
                    return dto;
                })
                .collect(Collectors.toList());

        return ResponseEntity.ok(quizDtos);
    }

    // ================== ANALYTICS GLOBALES DU PROF ==================

    @GetMapping("/analytics")
    public ResponseEntity<CourseAnalyticsDto> analytics(
            @RequestHeader("Authorization") String bearer
    ) {
        User teacher = getTeacherFromBearer(bearer);

        long totalStudents =
                enrollmentRepository.countDistinctStudentByTeacherId(teacher.getId());
        long activeCourses =
                courseRepository.countByTeacher(teacher);
        double avgRating =
                enrollmentRepository.avgRatingByTeacherId(teacher.getId());

        CourseAnalyticsDto dto = new CourseAnalyticsDto(
                totalStudents,
                activeCourses,
                avgRating
        );

        return ResponseEntity.ok(dto);
    }

    // ================== GESTION DES QUIZ ==================

    @PostMapping("/{courseId}/quiz")
    @Transactional
    public ResponseEntity<Quiz> createQuiz(
            @RequestHeader("Authorization") String bearer,
            @PathVariable("courseId") Long courseId,
            @RequestBody CreateQuizRequest request
    ) {
        User teacher = getTeacherFromBearer(bearer);

        Course course = courseRepository.findById(courseId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Cours introuvable"
                ));

        // Vérifier que le cours appartient au professeur
        if (!course.getTeacher().getId().equals(teacher.getId())) {
            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN,
                    "Vous n'êtes pas autorisé à créer un quiz pour ce cours"
            );
        }

        // Vérifier si un quiz existe déjà
        if (quizRepository.findByCourseId(courseId).isPresent()) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Un quiz existe déjà pour ce cours"
            );
        }

        // Créer le quiz
        Quiz quiz = Quiz.builder()
                .course(course)
                .title(request.getTitle())
                .description(request.getDescription())
                .passingScore(request.getPassingScore() != null ? request.getPassingScore() : 75)
                .maxAttempts(request.getMaxAttempts() != null ? request.getMaxAttempts() : 3)
                .level(request.getLevel() != null ? request.getLevel() : com.elearnia.entities.QuizLevel.BEGINNER)
                .build();

        // Créer les questions
        if (request.getQuestions() != null && !request.getQuestions().isEmpty()) {
            List<Question> questions = request.getQuestions().stream()
                    .map(qReq -> Question.builder()
                            .quiz(quiz)
                            .text(qReq.getText())
                            .correctAnswer(qReq.getCorrectAnswer())
                            .options(qReq.getOptions())
                            .points(qReq.getPoints() != null ? qReq.getPoints() : 1)
                            .build())
                    .collect(Collectors.toList());
            quiz.setQuestions(questions);
        }

        Quiz saved = quizRepository.save(quiz);
        return ResponseEntity.ok(saved);
    }

    @GetMapping("/{courseId}/quiz")
    public ResponseEntity<Quiz> getQuiz(
            @RequestHeader("Authorization") String bearer,
            @PathVariable("courseId") Long courseId
    ) {
        User teacher = getTeacherFromBearer(bearer);

        Course course = courseRepository.findById(courseId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Cours introuvable"
                ));

        // Vérifier que le cours appartient au professeur
        if (!course.getTeacher().getId().equals(teacher.getId())) {
            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN,
                    "Vous n'êtes pas autorisé à voir ce quiz"
            );
        }

        Quiz quiz = quizRepository.findByCourseId(courseId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Aucun quiz trouvé pour ce cours"
                ));

        return ResponseEntity.ok(quiz);
    }

    @PutMapping("/{courseId}/quiz")
    @Transactional
    public ResponseEntity<Quiz> updateQuiz(
            @RequestHeader("Authorization") String bearer,
            @PathVariable("courseId") Long courseId,
            @RequestBody CreateQuizRequest request
    ) {
        User teacher = getTeacherFromBearer(bearer);

        Course course = courseRepository.findById(courseId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Cours introuvable"
                ));

        // Vérifier que le cours appartient au professeur
        if (!course.getTeacher().getId().equals(teacher.getId())) {
            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN,
                    "Vous n'êtes pas autorisé à modifier ce quiz"
            );
        }

        Quiz quiz = quizRepository.findByCourseId(courseId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Aucun quiz trouvé pour ce cours"
                ));

        // Mettre à jour le quiz
        if (request.getTitle() != null) {
            quiz.setTitle(request.getTitle());
        }
        if (request.getDescription() != null) {
            quiz.setDescription(request.getDescription());
        }
        if (request.getPassingScore() != null) {
            quiz.setPassingScore(request.getPassingScore());
        }
        if (request.getMaxAttempts() != null) {
            quiz.setMaxAttempts(request.getMaxAttempts());
        }
        if (request.getLevel() != null) {
            quiz.setLevel(request.getLevel());
        }

        // Mettre à jour les questions (supprimer les anciennes et créer les nouvelles)
        if (request.getQuestions() != null) {
            quiz.getQuestions().clear();
            List<Question> newQuestions = request.getQuestions().stream()
                    .map(qReq -> Question.builder()
                            .quiz(quiz)
                            .text(qReq.getText())
                            .correctAnswer(qReq.getCorrectAnswer())
                            .options(qReq.getOptions())
                            .points(qReq.getPoints() != null ? qReq.getPoints() : 1)
                            .build())
                    .collect(Collectors.toList());
            quiz.getQuestions().addAll(newQuestions);
        }

        Quiz saved = quizRepository.save(quiz);
        return ResponseEntity.ok(saved);
    }

    @DeleteMapping("/{courseId}/quiz")
    @Transactional
    public ResponseEntity<Void> deleteQuiz(
            @RequestHeader("Authorization") String bearer,
            @PathVariable("courseId") Long courseId
    ) {
        User teacher = getTeacherFromBearer(bearer);

        Course course = courseRepository.findById(courseId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Cours introuvable"
                ));

        // Vérifier que le cours appartient au professeur
        if (!course.getTeacher().getId().equals(teacher.getId())) {
            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN,
                    "Vous n'êtes pas autorisé à supprimer ce quiz"
            );
        }

        Quiz quiz = quizRepository.findByCourseId(courseId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Aucun quiz trouvé pour ce cours"
                ));

        // Supprimer d'abord toutes les tentatives de quiz associées
        quizAttemptRepository.deleteByQuizId(quiz.getId());
        
        // Supprimer toutes les questions du quiz
        questionRepository.deleteByQuizId(quiz.getId());
        
        // Enfin, supprimer le quiz
        quizRepository.delete(quiz);
        return ResponseEntity.noContent().build();
    }

    // ================== GESTION DES REVIEWS ==================

    @GetMapping("/{courseId}/reviews")
    public ResponseEntity<List<ReviewDto>> getCourseReviews(
            @RequestHeader("Authorization") String bearer,
            @PathVariable("courseId") Long courseId
    ) {
        User teacher = getTeacherFromBearer(bearer);

        Course course = courseRepository.findById(courseId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Cours introuvable"
                ));

        if (!course.getTeacher().getId().equals(teacher.getId())) {
            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN,
                    "Vous n'êtes pas autorisé à voir les avis de ce cours"
            );
        }

        List<Review> reviews = reviewRepository.findByCourseId(courseId);
        List<ReviewDto> dtos = reviews.stream()
                .map(ReviewDto::fromEntity)
                .collect(Collectors.toList());

        return ResponseEntity.ok(dtos);
    }

    @PutMapping("/reviews/{reviewId}/approve")
    public ResponseEntity<ReviewDto> approveReview(
            @RequestHeader("Authorization") String bearer,
            @PathVariable("reviewId") Long reviewId
    ) {
        User teacher = getTeacherFromBearer(bearer);

        Review review = reviewRepository.findById(reviewId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Avis introuvable"
                ));

        Course course = review.getCourse();
        if (!course.getTeacher().getId().equals(teacher.getId())) {
            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN,
                    "Vous n'êtes pas autorisé à approuver cet avis"
            );
        }

        review.setStatus(Review.ReviewStatus.APPROVED);
        Review saved = reviewRepository.save(review);

        return ResponseEntity.ok(ReviewDto.fromEntity(saved));
    }

    @PutMapping("/reviews/{reviewId}/reject")
    public ResponseEntity<ReviewDto> rejectReview(
            @RequestHeader("Authorization") String bearer,
            @PathVariable("reviewId") Long reviewId
    ) {
        User teacher = getTeacherFromBearer(bearer);

        Review review = reviewRepository.findById(reviewId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Avis introuvable"
                ));

        Course course = review.getCourse();
        if (!course.getTeacher().getId().equals(teacher.getId())) {
            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN,
                    "Vous n'êtes pas autorisé à rejeter cet avis"
            );
        }

        review.setStatus(Review.ReviewStatus.REJECTED);
        Review saved = reviewRepository.save(review);

        return ResponseEntity.ok(ReviewDto.fromEntity(saved));
    }

    // ================== GESTION DES QUIZ STANDALONE ==================

    @PostMapping("/quiz/generate")
    @Transactional
    public ResponseEntity<Quiz> generateQuizWithAI(
            @RequestHeader("Authorization") String bearer,
            @RequestBody GenerateQuizRequest request
    ) {
        User teacher = getTeacherFromBearer(bearer);

        // Convertir le niveau de difficulté en String pour le service IA
        String difficulty = request.getDifficulty() != null 
                ? request.getDifficulty().name() 
                : "BEGINNER";
        
        // Normaliser le niveau pour le service IA
        String normalizedDifficulty = difficulty.equals("BEGINNER") ? "débutant" :
                                     difficulty.equals("ADVANCED") ? "avancé" : "intermédiaire";

        // Générer le quiz avec l'IA
        GeneratedQuizDto generatedQuiz = aiCourseGeneratorService.generateStandaloneQuiz(
                request.getTopic(),
                normalizedDifficulty
        );

        // Créer le quiz standalone
        Quiz quiz = new Quiz();
        quiz.setCourse(null); // Pas de cours associé - quiz standalone
        quiz.setTitle(generatedQuiz.getTitle());
        quiz.setDescription(generatedQuiz.getDescription());
        quiz.setPassingScore(75); // Score minimum par défaut
        quiz.setMaxAttempts(3); // 3 tentatives par défaut
        quiz.setLevel(request.getDifficulty() != null ? request.getDifficulty() : com.elearnia.entities.QuizLevel.BEGINNER);

        // Créer les questions générées
        if (generatedQuiz.getQuestions() != null && !generatedQuiz.getQuestions().isEmpty()) {
            List<Question> questions = generatedQuiz.getQuestions().stream()
                    .map(qDto -> Question.builder()
                            .quiz(quiz)
                            .text(qDto.getText())
                            .correctAnswer(qDto.getCorrectAnswer())
                            .options(qDto.getOptions())
                            .points(qDto.getPoints() != null ? qDto.getPoints() : 1)
                            .build())
                    .collect(Collectors.toList());
            quiz.setQuestions(questions);
        }

        Quiz saved = quizRepository.save(quiz);
        return ResponseEntity.ok(saved);
    }

    @PostMapping("/quiz")
    @Transactional
    public ResponseEntity<Quiz> createStandaloneQuiz(
            @RequestHeader("Authorization") String bearer,
            @RequestBody CreateQuizRequest request
    ) {
        User teacher = getTeacherFromBearer(bearer);

        // Créer un quiz standalone (sans cours) - utiliser le constructeur au lieu du builder pour éviter les problèmes avec null
        Quiz quiz = new Quiz();
        quiz.setCourse(null); // Pas de cours associé - quiz standalone
        quiz.setTitle(request.getTitle());
        quiz.setDescription(request.getDescription());
        quiz.setPassingScore(request.getPassingScore() != null ? request.getPassingScore() : 75);
        quiz.setMaxAttempts(request.getMaxAttempts() != null ? request.getMaxAttempts() : 3);
        quiz.setLevel(request.getLevel() != null ? request.getLevel() : com.elearnia.entities.QuizLevel.BEGINNER);

        // Créer les questions
        if (request.getQuestions() != null && !request.getQuestions().isEmpty()) {
            List<Question> questions = request.getQuestions().stream()
                    .map(qReq -> Question.builder()
                            .quiz(quiz)
                            .text(qReq.getText())
                            .correctAnswer(qReq.getCorrectAnswer())
                            .options(qReq.getOptions())
                            .points(qReq.getPoints() != null ? qReq.getPoints() : 1)
                            .build())
                    .collect(Collectors.toList());
            quiz.setQuestions(questions);
        }

        Quiz saved = quizRepository.save(quiz);
        return ResponseEntity.ok(saved);
    }

    // Récupérer un quiz standalone par ID
    @GetMapping("/quiz/{quizId}")
    public ResponseEntity<Quiz> getStandaloneQuiz(
            @RequestHeader("Authorization") String bearer,
            @PathVariable("quizId") Long quizId
    ) {
        User teacher = getTeacherFromBearer(bearer);

        Quiz quiz = quizRepository.findById(quizId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Quiz introuvable"
                ));

        // Vérifier que c'est un quiz standalone ou qu'il appartient au professeur
        if (quiz.getCourse() != null && !quiz.getCourse().getTeacher().getId().equals(teacher.getId())) {
            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN,
                    "Vous n'êtes pas autorisé à voir ce quiz"
            );
        }

        return ResponseEntity.ok(quiz);
    }

    // Mettre à jour un quiz standalone
    @PutMapping("/quiz/{quizId}")
    @Transactional
    public ResponseEntity<Quiz> updateStandaloneQuiz(
            @RequestHeader("Authorization") String bearer,
            @PathVariable("quizId") Long quizId,
            @RequestBody CreateQuizRequest request
    ) {
        User teacher = getTeacherFromBearer(bearer);

        Quiz quiz = quizRepository.findById(quizId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Quiz introuvable"
                ));

        // Vérifier que c'est un quiz standalone ou qu'il appartient au professeur
        if (quiz.getCourse() != null && !quiz.getCourse().getTeacher().getId().equals(teacher.getId())) {
            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN,
                    "Vous n'êtes pas autorisé à modifier ce quiz"
            );
        }

        // Mettre à jour le quiz
        if (request.getTitle() != null) {
            quiz.setTitle(request.getTitle());
        }
        if (request.getDescription() != null) {
            quiz.setDescription(request.getDescription());
        }
        if (request.getPassingScore() != null) {
            quiz.setPassingScore(request.getPassingScore());
        }
        if (request.getMaxAttempts() != null) {
            quiz.setMaxAttempts(request.getMaxAttempts());
        }
        if (request.getLevel() != null) {
            quiz.setLevel(request.getLevel());
        }

        // Mettre à jour les questions (supprimer les anciennes et créer les nouvelles)
        if (request.getQuestions() != null) {
            quiz.getQuestions().clear();
            List<Question> newQuestions = request.getQuestions().stream()
                    .map(qReq -> Question.builder()
                            .quiz(quiz)
                            .text(qReq.getText())
                            .correctAnswer(qReq.getCorrectAnswer())
                            .options(qReq.getOptions())
                            .points(qReq.getPoints() != null ? qReq.getPoints() : 1)
                            .build())
                    .collect(Collectors.toList());
            quiz.getQuestions().addAll(newQuestions);
        }

        Quiz saved = quizRepository.save(quiz);
        return ResponseEntity.ok(saved);
    }

    // Supprimer un quiz standalone
    @DeleteMapping("/quiz/{quizId}")
    @Transactional
    public ResponseEntity<Void> deleteStandaloneQuiz(
            @RequestHeader("Authorization") String bearer,
            @PathVariable("quizId") Long quizId
    ) {
        User teacher = getTeacherFromBearer(bearer);

        Quiz quiz = quizRepository.findById(quizId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Quiz introuvable"
                ));

        // Vérifier que c'est un quiz standalone ou qu'il appartient au professeur
        if (quiz.getCourse() != null && !quiz.getCourse().getTeacher().getId().equals(teacher.getId())) {
            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN,
                    "Vous n'êtes pas autorisé à supprimer ce quiz"
            );
        }

        // Supprimer d'abord toutes les tentatives de quiz associées
        quizAttemptRepository.deleteByQuizId(quiz.getId());
        
        // Supprimer toutes les questions du quiz
        questionRepository.deleteByQuizId(quiz.getId());
        
        // Enfin, supprimer le quiz
        quizRepository.delete(quiz);
        return ResponseEntity.noContent().build();
    }

    // ================== GESTION DES TENTATIVES DE QUIZ ==================

    @GetMapping("/{courseId}/students/{studentId}/quiz-attempts")
    public ResponseEntity<List<QuizAttemptDto>> getStudentQuizAttempts(
            @RequestHeader("Authorization") String bearer,
            @PathVariable("courseId") Long courseId,
            @PathVariable("studentId") Long studentId
    ) {
        User teacher = getTeacherFromBearer(bearer);

        Course course = courseRepository.findById(courseId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Cours introuvable"
                ));

        if (!course.getTeacher().getId().equals(teacher.getId())) {
            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN,
                    "Vous n'êtes pas autorisé à voir les tentatives de ce cours"
            );
        }

        Quiz quiz = quizRepository.findByCourseId(courseId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Aucun quiz trouvé pour ce cours"
                ));

        List<QuizAttempt> attempts = quizAttemptRepository
                .findByUserIdAndQuizIdOrderByAttemptNumberDesc(studentId, quiz.getId());

        List<QuizAttemptDto> dtos = attempts.stream()
                .map(attempt -> new QuizAttemptDto(
                        attempt.getId(),
                        attempt.getUser().getFullName(),
                        attempt.getAttemptNumber(),
                        attempt.getScore(),
                        attempt.isPassed(),
                        attempt.getCompletedAt()
                ))
                .collect(Collectors.toList());

        return ResponseEntity.ok(dtos);
    }

    @DeleteMapping("/{courseId}/students/{studentId}/quiz-attempts")
    @Transactional
    public ResponseEntity<Void> resetStudentQuizAttempts(
            @RequestHeader("Authorization") String bearer,
            @PathVariable("courseId") Long courseId,
            @PathVariable("studentId") Long studentId
    ) {
        User teacher = getTeacherFromBearer(bearer);

        Course course = courseRepository.findById(courseId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Cours introuvable"
                ));

        if (!course.getTeacher().getId().equals(teacher.getId())) {
            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN,
                    "Vous n'êtes pas autorisé à réinitialiser les tentatives de ce cours"
            );
        }

        Quiz quiz = quizRepository.findByCourseId(courseId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Aucun quiz trouvé pour ce cours"
                ));

        // Supprimer toutes les tentatives de l'étudiant pour ce quiz
        List<QuizAttempt> attempts = quizAttemptRepository
                .findByUserIdAndQuizIdOrderByAttemptNumberDesc(studentId, quiz.getId());
        quizAttemptRepository.deleteAll(attempts);

        return ResponseEntity.noContent().build();
    }

    // Réinitialiser la progression d'un étudiant pour un cours
    @PutMapping("/{courseId}/students/{studentId}/reset-progress")
    @Transactional
    public ResponseEntity<Void> resetStudentProgress(
            @RequestHeader("Authorization") String bearer,
            @PathVariable("courseId") Long courseId,
            @PathVariable("studentId") Long studentId
    ) {
        if (bearer == null || bearer.trim().isEmpty()) {
            throw new ResponseStatusException(
                    HttpStatus.UNAUTHORIZED,
                    "Token d'authentification manquant"
            );
        }

        User teacher = getTeacherFromBearer(bearer);

        // Vérifier que l'utilisateur est bien un professeur
        if (teacher.getRole() != com.elearnia.model.Role.TEACHER) {
            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN,
                    "Seuls les professeurs peuvent réinitialiser la progression des étudiants"
            );
        }

        Course course = courseRepository.findById(courseId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Cours introuvable"
                ));

        // Vérifier que le professeur est bien le propriétaire du cours
        if (course.getTeacher() == null) {
            throw new ResponseStatusException(
                    HttpStatus.INTERNAL_SERVER_ERROR,
                    "Le cours n'a pas de professeur associé"
            );
        }
        
        Long courseTeacherId = course.getTeacher().getId();
        Long teacherId = teacher.getId();
        
        if (!courseTeacherId.equals(teacherId)) {
            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN,
                    String.format("Vous n'êtes pas autorisé à réinitialiser la progression pour ce cours. " +
                            "Le cours appartient au professeur ID: %d, mais vous êtes ID: %d", 
                            courseTeacherId, teacherId)
            );
        }

        Enrollment enrollment = enrollmentRepository
                .findByStudentIdAndCourseId(studentId, courseId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Inscription de l'étudiant non trouvée"
                ));

        // Réinitialiser la progression à 0% et marquer comme non complété
        enrollment.setProgress(0.0);
        enrollment.setCompleted(false);
        enrollmentRepository.save(enrollment);

        return ResponseEntity.noContent().build();
    }

    // ================== CONSULTATION DES SCORES DES ÉTUDIANTS ==================

    @GetMapping("/quiz/{quizId}/scores")
    public ResponseEntity<List<StudentQuizScoreDto>> getQuizScores(
            @RequestHeader("Authorization") String bearer,
            @PathVariable("quizId") Long quizId
    ) {
        User teacher = getTeacherFromBearer(bearer);

        Quiz quiz = quizRepository.findById(quizId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Quiz introuvable"
                ));

        // Si le quiz est lié à un cours, vérifier que le prof est propriétaire
        if (quiz.getCourse() != null && !quiz.getCourse().getTeacher().getId().equals(teacher.getId())) {
            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN,
                    "Vous n'êtes pas autorisé à voir les scores de ce quiz"
            );
        }

        // Récupérer toutes les tentatives pour ce quiz
        List<QuizAttempt> attempts = quizAttemptRepository
                .findByQuizIdOrderByCompletedAtDesc(quizId);

        List<StudentQuizScoreDto> scores = attempts.stream()
                .map(attempt -> new StudentQuizScoreDto(
                        attempt.getId(),
                        attempt.getUser().getId(),
                        attempt.getUser().getFullName(),
                        attempt.getUser().getEmail(),
                        attempt.getScore(),
                        attempt.isPassed(),
                        attempt.getAttemptNumber(),
                        attempt.getCompletedAt()
                ))
                .collect(Collectors.toList());

        return ResponseEntity.ok(scores);
    }

    @GetMapping("/quizzes/scores")
    public ResponseEntity<List<AllQuizzesScoresDto>> getAllQuizzesScores(
            @RequestHeader("Authorization") String bearer
    ) {
        User teacher = getTeacherFromBearer(bearer);

        // Récupérer tous les quizzes (standalone et liés aux cours du prof)
        List<Quiz> allQuizzes = quizRepository.findAll();
        
        // Filtrer pour ne garder que les quizzes du prof ou standalone
        List<Quiz> teacherQuizzes = allQuizzes.stream()
                .filter(quiz -> quiz.getCourse() == null || 
                        quiz.getCourse().getTeacher().getId().equals(teacher.getId()))
                .collect(Collectors.toList());

        List<AllQuizzesScoresDto> result = teacherQuizzes.stream()
                .map(quiz -> {
                    List<QuizAttempt> attempts = quizAttemptRepository
                            .findByQuizIdOrderByCompletedAtDesc(quiz.getId());
                    
                    List<StudentQuizScoreDto> scores = attempts.stream()
                            .map(attempt -> new StudentQuizScoreDto(
                                    attempt.getId(),
                                    attempt.getUser().getId(),
                                    attempt.getUser().getFullName(),
                                    attempt.getUser().getEmail(),
                                    attempt.getScore(),
                                    attempt.isPassed(),
                                    attempt.getAttemptNumber(),
                                    attempt.getCompletedAt()
                            ))
                            .collect(Collectors.toList());

                    return new AllQuizzesScoresDto(
                            quiz.getId(),
                            quiz.getTitle(),
                            quiz.getLevel().name(),
                            quiz.getCourse() != null ? quiz.getCourse().getTitle() : "Quiz standalone",
                            scores
                    );
                })
                .collect(Collectors.toList());

        return ResponseEntity.ok(result);
    }
}
