package com.elearnia.controller;

import com.elearnia.dto.*;
import com.elearnia.entities.*;
import com.elearnia.model.User;
import com.elearnia.repository.*;
import com.elearnia.security.JwtService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/student/quizzes")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class QuizController {

    private final QuizRepository quizRepository;
    private final QuizAttemptRepository quizAttemptRepository;
    private final EnrollmentRepository enrollmentRepository;
    private final LessonRepository lessonRepository;
    private final UserRepository userRepository;
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

    // Récupérer le quiz d'un cours
    @GetMapping("/course/{courseId}")
    public ResponseEntity<QuizDto> getQuizByCourse(
            @RequestHeader("Authorization") String bearer,
            @PathVariable("courseId") Long courseId
    ) {
        User student = getUserFromBearer(bearer);

        // Vérifier que l'étudiant est inscrit au cours
        enrollmentRepository.findByStudentIdAndCourseId(student.getId(), courseId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Vous n'êtes pas inscrit à ce cours"
                ));

        Quiz quiz = quizRepository.findByCourseId(courseId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Aucun quiz disponible pour ce cours"
                ));

        // Calculer le nombre de tentatives restantes
        int attemptCount = quizAttemptRepository.countByUserIdAndQuizId(student.getId(), quiz.getId());
        int remainingAttempts = Math.max(0, quiz.getMaxAttempts() - attemptCount);

        QuizDto dto = convertToDto(quiz, remainingAttempts);
        return ResponseEntity.ok(dto);
    }

    // Soumettre les réponses du quiz
    @PostMapping("/course/{courseId}/submit")
    public ResponseEntity<QuizResultDto> submitQuiz(
            @RequestHeader("Authorization") String bearer,
            @PathVariable("courseId") Long courseId,
            @RequestBody SubmitQuizRequest request
    ) {
        User student = getUserFromBearer(bearer);

        // Vérifier que l'étudiant est inscrit au cours
        Enrollment enrollment = enrollmentRepository.findByStudentIdAndCourseId(student.getId(), courseId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Vous n'êtes pas inscrit à ce cours"
                ));

        Quiz quiz = quizRepository.findByCourseId(courseId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Aucun quiz disponible pour ce cours"
                ));

        // Vérifier le nombre de tentatives
        int attemptCount = quizAttemptRepository.countByUserIdAndQuizId(student.getId(), quiz.getId());
        if (attemptCount >= quiz.getMaxAttempts()) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Vous avez atteint le nombre maximum de tentatives (" + quiz.getMaxAttempts() + ")"
            );
        }

        // Calculer le score
        int totalPoints = 0;
        int earnedPoints = 0;

        // Convertir Map<String, String> en Map<Long, String>
        Map<Long, String> answersMap = new HashMap<>();
        for (java.util.Map.Entry<String, String> entry : request.getAnswers().entrySet()) {
            try {
                Long questionId = Long.parseLong(entry.getKey());
                answersMap.put(questionId, entry.getValue());
            } catch (NumberFormatException e) {
                // Ignorer les clés invalides
            }
        }

        for (Question question : quiz.getQuestions()) {
            totalPoints += question.getPoints();
            String studentAnswer = answersMap.get(question.getId());
            if (studentAnswer != null && studentAnswer.equalsIgnoreCase(question.getCorrectAnswer())) {
                earnedPoints += question.getPoints();
            }
        }

        double score = totalPoints > 0 ? (earnedPoints * 100.0 / totalPoints) : 0;
        boolean passed = score >= quiz.getPassingScore();
        int attemptNumber = attemptCount + 1;

        // Enregistrer la tentative
        QuizAttempt attempt = QuizAttempt.builder()
                .user(student)
                .quiz(quiz)
                .attemptNumber(attemptNumber)
                .score(score)
                .passed(passed)
                .answers(answersMap)
                .build();

        quizAttemptRepository.save(attempt);

        // Vérifier si tous les quizzes du cours sont réussis
        boolean courseCompleted = false;
        if (passed) {
            // Vérifier si tous les quizzes des leçons sont réussis
            boolean allQuizzesPassed = checkAllQuizzesPassed(student.getId(), courseId);
            if (allQuizzesPassed && !enrollment.isCompleted()) {
                enrollment.setCompleted(true);
                enrollment.setProgress(100.0);
                enrollmentRepository.save(enrollment);
                courseCompleted = true;
            }
        }

        QuizResultDto result = new QuizResultDto(
                score,
                passed,
                attemptNumber,
                quiz.getMaxAttempts() - attemptNumber,
                courseCompleted
        );

        return ResponseEntity.ok(result);
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

    // Récupérer les tentatives d'un étudiant pour un quiz
    @GetMapping("/course/{courseId}/attempts")
    public ResponseEntity<List<QuizAttempt>> getAttempts(
            @RequestHeader("Authorization") String bearer,
            @PathVariable("courseId") Long courseId
    ) {
        User student = getUserFromBearer(bearer);

        Quiz quiz = quizRepository.findByCourseId(courseId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Aucun quiz disponible pour ce cours"
                ));

        List<QuizAttempt> attempts = quizAttemptRepository
                .findByUserIdAndQuizIdOrderByAttemptNumberDesc(student.getId(), quiz.getId());

        return ResponseEntity.ok(attempts);
    }

    // Récupérer tous les quizzes disponibles (standalone)
    @GetMapping("/available")
    public ResponseEntity<List<QuizSummaryDto>> getAvailableQuizzes(
            @RequestHeader(value = "Authorization", required = false) String bearer,
            @RequestParam(required = false) String level
    ) {
        try {
            if (bearer == null || bearer.trim().isEmpty()) {
                throw new ResponseStatusException(
                        HttpStatus.UNAUTHORIZED,
                        "Token d'authentification manquant"
                );
            }
            User student = getUserFromBearer(bearer);

        List<Quiz> quizzes;
        if (level != null && !level.isEmpty() && !level.equalsIgnoreCase("ALL")) {
            try {
                com.elearnia.entities.QuizLevel quizLevel = com.elearnia.entities.QuizLevel.valueOf(level.toUpperCase());
                quizzes = quizRepository.findByCourseIdIsNullAndLevel(quizLevel);
            } catch (IllegalArgumentException e) {
                // Si le niveau n'est pas valide, retourner tous les quizzes standalone
                quizzes = quizRepository.findByCourseIdIsNull();
            }
        } else {
            quizzes = quizRepository.findByCourseIdIsNull();
        }

        List<QuizSummaryDto> dtos = quizzes.stream()
                .filter(quiz -> quiz != null && quiz.getId() != null) // Filtrer les quizzes null ou invalides
                .map(quiz -> {
                    try {
                        // Calculer les tentatives restantes pour cet étudiant
                        int attemptCount = quizAttemptRepository.countByUserIdAndQuizId(student.getId(), quiz.getId());
                        int remainingAttempts = Math.max(0, quiz.getMaxAttempts() - attemptCount);
                        
                        // Gérer les cas où level ou questions pourraient être null
                        String levelName = "BEGINNER";
                        if (quiz.getLevel() != null) {
                            try {
                                levelName = quiz.getLevel().name();
                            } catch (Exception e) {
                                levelName = "BEGINNER";
                            }
                        }
                        
                        int questionCount = 0;
                        if (quiz.getQuestions() != null) {
                            questionCount = quiz.getQuestions().size();
                        }
                        
                        return new QuizSummaryDto(
                                quiz.getId(),
                                quiz.getTitle() != null ? quiz.getTitle() : "Sans titre",
                                quiz.getDescription() != null ? quiz.getDescription() : "",
                                quiz.getPassingScore(),
                                quiz.getMaxAttempts(),
                                remainingAttempts,
                                levelName,
                                questionCount
                        );
                    } catch (Exception e) {
                        // Logger l'erreur et retourner null pour filtrer ce quiz
                        System.err.println("Erreur lors de la conversion du quiz " + quiz.getId() + ": " + e.getMessage());
                        e.printStackTrace();
                        return null;
                    }
                })
                .filter(dto -> dto != null) // Filtrer les DTOs null
                .collect(Collectors.toList());

            return ResponseEntity.ok(dtos);
        } catch (RuntimeException e) {
            // Si l'utilisateur n'est pas authentifié ou autre erreur
            System.err.println("Erreur dans getAvailableQuizzes: " + e.getMessage());
            e.printStackTrace();
            throw new ResponseStatusException(
                    HttpStatus.UNAUTHORIZED,
                    "Authentification requise"
            );
        } catch (Exception e) {
            // Autres erreurs
            System.err.println("Erreur inattendue dans getAvailableQuizzes: " + e.getMessage());
            e.printStackTrace();
            throw new ResponseStatusException(
                    HttpStatus.INTERNAL_SERVER_ERROR,
                    "Erreur lors de la récupération des quizzes"
            );
        }
    }

    // Récupérer un quiz standalone par ID
    @GetMapping("/{quizId}")
    public ResponseEntity<QuizDto> getQuizById(
            @RequestHeader("Authorization") String bearer,
            @PathVariable("quizId") Long quizId
    ) {
        User student = getUserFromBearer(bearer);

        Quiz quiz = quizRepository.findById(quizId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Quiz introuvable"
                ));

        // Calculer les tentatives restantes
        int attemptCount = quizAttemptRepository.countByUserIdAndQuizId(student.getId(), quiz.getId());
        int remainingAttempts = Math.max(0, quiz.getMaxAttempts() - attemptCount);

        QuizDto dto = convertToDto(quiz, remainingAttempts);
        return ResponseEntity.ok(dto);
    }

    // Soumettre un quiz standalone (pas lié à un cours)
    @PostMapping("/{quizId}/submit")
    public ResponseEntity<QuizResultDto> submitStandaloneQuiz(
            @RequestHeader("Authorization") String bearer,
            @PathVariable("quizId") Long quizId,
            @RequestBody SubmitQuizRequest request
    ) {
        User student = getUserFromBearer(bearer);

        Quiz quiz = quizRepository.findById(quizId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Quiz introuvable"
                ));

        // Vérifier le nombre de tentatives
        int attemptCount = quizAttemptRepository.countByUserIdAndQuizId(student.getId(), quiz.getId());
        if (attemptCount >= quiz.getMaxAttempts()) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Vous avez atteint le nombre maximum de tentatives (" + quiz.getMaxAttempts() + ")"
            );
        }

        // Calculer le score
        int totalPoints = 0;
        int earnedPoints = 0;

        Map<Long, String> answersMap = new HashMap<>();
        for (java.util.Map.Entry<String, String> entry : request.getAnswers().entrySet()) {
            try {
                Long questionId = Long.parseLong(entry.getKey());
                answersMap.put(questionId, entry.getValue());
            } catch (NumberFormatException e) {
                // Ignorer les clés invalides
            }
        }

        for (Question question : quiz.getQuestions()) {
            totalPoints += question.getPoints();
            String studentAnswer = answersMap.get(question.getId());
            if (studentAnswer != null && studentAnswer.equalsIgnoreCase(question.getCorrectAnswer())) {
                earnedPoints += question.getPoints();
            }
        }

        double score = totalPoints > 0 ? (earnedPoints * 100.0 / totalPoints) : 0;
        boolean passed = score >= quiz.getPassingScore();
        int attemptNumber = attemptCount + 1;

        // Enregistrer la tentative
        QuizAttempt attempt = QuizAttempt.builder()
                .user(student)
                .quiz(quiz)
                .attemptNumber(attemptNumber)
                .score(score)
                .passed(passed)
                .answers(answersMap)
                .build();

        quizAttemptRepository.save(attempt);

        QuizResultDto result = new QuizResultDto(
                score,
                passed,
                attemptNumber,
                quiz.getMaxAttempts() - attemptNumber,
                false // Pas de completion de cours pour les quizzes standalone
        );

        return ResponseEntity.ok(result);
    }

    private QuizDto convertToDto(Quiz quiz, int remainingAttempts) {
        List<QuestionDto> questionDtos = quiz.getQuestions().stream()
                .map(q -> new QuestionDto(
                        q.getId(),
                        q.getText(),
                        q.getOptions(),
                        q.getPoints()
                ))
                .collect(Collectors.toList());

        // Récupérer l'ID du cours si le quiz est lié à un cours
        Long courseId = quiz.getCourse() != null ? quiz.getCourse().getId() : null;

        return new QuizDto(
                quiz.getId(),
                quiz.getTitle(),
                quiz.getDescription(),
                quiz.getPassingScore(),
                quiz.getMaxAttempts(),
                remainingAttempts,
                quiz.getLevel(),
                courseId,
                questionDtos
        );
    }
}

