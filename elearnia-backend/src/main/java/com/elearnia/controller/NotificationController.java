package com.elearnia.controller;

import com.elearnia.entities.Notification;
import com.elearnia.model.User;
import com.elearnia.repository.NotificationRepository;
import com.elearnia.repository.UserRepository;
import com.elearnia.security.JwtService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.Collections;
import java.util.List;

@RestController
@RequestMapping("/notifications")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class NotificationController {

    private final NotificationRepository notificationRepository;
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

    @GetMapping
    public ResponseEntity<List<Notification>> getNotifications(
            @RequestHeader("Authorization") String bearer
    ) {
        try {
            User user = getUserFromBearer(bearer);
            List<Notification> notifications = notificationRepository
                    .findByUserIdOrderByCreatedAtDesc(user.getId());
            return ResponseEntity.ok(notifications);
        } catch (Exception e) {
            // Si la table n'existe pas encore, retourner une liste vide au lieu d'une erreur
            if (e.getMessage() != null && e.getMessage().contains("doesn't exist")) {
                return ResponseEntity.ok(Collections.emptyList());
            }
            throw new ResponseStatusException(
                    HttpStatus.INTERNAL_SERVER_ERROR,
                    "Erreur lors de la récupération des notifications: " + e.getMessage()
            );
        }
    }

    @GetMapping("/unread")
    public ResponseEntity<List<Notification>> getUnreadNotifications(
            @RequestHeader("Authorization") String bearer
    ) {
        try {
            User user = getUserFromBearer(bearer);
            List<Notification> notifications = notificationRepository
                    .findByUserIdAndReadFalseOrderByCreatedAtDesc(user.getId());
            return ResponseEntity.ok(notifications);
        } catch (Exception e) {
            // Si la table n'existe pas encore, retourner une liste vide
            if (e.getMessage() != null && e.getMessage().contains("doesn't exist")) {
                return ResponseEntity.ok(Collections.emptyList());
            }
            throw new ResponseStatusException(
                    HttpStatus.INTERNAL_SERVER_ERROR,
                    "Erreur lors de la récupération des notifications: " + e.getMessage()
            );
        }
    }

    @PutMapping("/{notificationId}/read")
    public ResponseEntity<Void> markAsRead(
            @RequestHeader("Authorization") String bearer,
            @PathVariable("notificationId") Long notificationId
    ) {
        User user = getUserFromBearer(bearer);
        Notification notification = notificationRepository.findById(notificationId)
                .orElseThrow(() -> new RuntimeException("Notification non trouvée"));

        // Vérifier que la notification appartient à l'utilisateur
        if (!notification.getUser().getId().equals(user.getId())) {
            throw new RuntimeException("Non autorisé");
        }

        notification.setRead(true);
        notificationRepository.save(notification);
        return ResponseEntity.noContent().build();
    }

    @PutMapping("/read-all")
    public ResponseEntity<Void> markAllAsRead(
            @RequestHeader("Authorization") String bearer
    ) {
        User user = getUserFromBearer(bearer);
        notificationRepository.markAllAsRead(user.getId());
        return ResponseEntity.noContent().build();
    }
}

