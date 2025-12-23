package com.elearnia.controller;

import com.elearnia.model.User;
import com.elearnia.repository.UserRepository;
import com.elearnia.security.JwtService;
import com.elearnia.service.ChatBotService;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/student/chatbot")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class ChatBotController {

    private final ChatBotService chatBotService;
    private final UserRepository userRepository;
    private final JwtService jwtService;

    @PostMapping("/message")
    public ResponseEntity<ChatBotResponse> sendMessage(
            @RequestHeader("Authorization") String bearer,
            @RequestBody ChatBotRequest request
    ) {
        User student = getUserFromBearer(bearer);

        String response = chatBotService.processMessage(request.getMessage(), student);

        return ResponseEntity.ok(new ChatBotResponse(response));
    }

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

    @Data
    public static class ChatBotRequest {
        private String message;
    }

    @Data
    public static class ChatBotResponse {
        private String response;

        public ChatBotResponse(String response) {
            this.response = response;
        }
    }
}










