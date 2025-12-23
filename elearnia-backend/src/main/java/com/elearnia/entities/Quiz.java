package com.elearnia.entities;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.*;
import lombok.*;

import java.util.List;

@Entity
@Table(name = "quizzes")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@JsonIgnoreProperties({"hibernateLazyInitializer", "handler", "course"})
public class Quiz {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "course_id", nullable = true)
    private Course course; // Optionnel : peut être null pour les quizzes standalone

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "lesson_id", nullable = true)
    private Lesson lesson; // Optionnel : quiz lié à une leçon spécifique

    @Column(nullable = false)
    private String title;

    @Column(length = 2000)
    private String description;

    @Builder.Default
    @Column(nullable = false)
    private int passingScore = 75; // Score minimum pour réussir (en pourcentage)

    @Builder.Default
    @Column(nullable = false)
    private int maxAttempts = 3; // Nombre maximum de tentatives

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    @Builder.Default
    private QuizLevel level = QuizLevel.BEGINNER; // Niveau du quiz

    @OneToMany(mappedBy = "quiz", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<Question> questions;
}

