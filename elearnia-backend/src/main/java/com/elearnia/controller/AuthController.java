package com.elearnia.controller;

import com.elearnia.dto.AuthRequest;
import com.elearnia.dto.AuthResponse;
import com.elearnia.dto.RegisterRequest;
import com.elearnia.dto.UpdateProfileRequest;
import com.elearnia.model.User;
import com.elearnia.service.AuthService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/auth")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")   // pour tester tranquille
public class AuthController {

    private final AuthService authService;

    @PostMapping("/register")
    public ResponseEntity<AuthResponse> register(@Valid @RequestBody RegisterRequest request) {
        return ResponseEntity.ok(authService.register(request));
    }

    @PostMapping("/login")
    public ResponseEntity<AuthResponse> login(@RequestBody AuthRequest request) {
        return ResponseEntity.ok(authService.authenticate(request));
    }

    @GetMapping("/me")
    public ResponseEntity<User> me(@RequestHeader("Authorization") String bearer) {
        String token = bearer.replace("Bearer ", "");
        User user = authService.getCurrentUserFromToken(token);
        return ResponseEntity.ok(user);
    }

    @PutMapping("/profile")
    public ResponseEntity<User> updateProfile(
            @RequestHeader("Authorization") String bearer,
            @RequestBody UpdateProfileRequest request
    ) {
        String token = bearer.replace("Bearer ", "");
        User updatedUser = authService.updateProfile(token, request);
        return ResponseEntity.ok(updatedUser);
    }
}
