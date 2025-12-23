package com.elearnia.entities;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.elearnia.model.User;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "notifications")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@JsonIgnoreProperties({"hibernateLazyInitializer", "handler", "user"})
public class Notification {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user; // Le professeur qui reçoit la notification

    @Column(nullable = false, length = 500)
    private String message;

    @Column(nullable = false)
    private String type; // "ENROLLMENT" ou "COMPLETION"

    @Builder.Default
    @Column(name = "`read`", nullable = false)
    private boolean read = false;

    @Column(nullable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }
}

