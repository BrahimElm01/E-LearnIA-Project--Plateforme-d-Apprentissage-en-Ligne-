package com.elearnia.service;

import com.elearnia.dto.AuthRequest;
import com.elearnia.dto.AuthResponse;
import com.elearnia.dto.RegisterRequest;
import com.elearnia.model.User;
import com.elearnia.repository.UserRepository;
import com.elearnia.security.JwtService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.http.HttpStatus;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final AuthenticationManager authenticationManager;
    private final JwtService jwtService;

    // ================== REGISTER ==================

    public AuthResponse register(RegisterRequest request) {

        // 1) vérifier si l'email existe déjà
        if (userRepository.existsByEmail(request.getEmail())) {
            // renvoie une vraie réponse HTTP 409 au lieu d'une RuntimeException
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "Email déjà utilisé"
            );
        }

        // 2) créer l'utilisateur
        User user = User.builder()
                .fullName(request.getFullName())
                .email(request.getEmail())
                .password(passwordEncoder.encode(request.getPassword()))
                .role(request.getRole())           // LEARNER / TEACHER
                .build();

        userRepository.save(user);

        // 3) générer token
        String token = jwtService.generateToken(user);

        return new AuthResponse(
                token,
                user.getFullName(),
                user.getEmail(),
                user.getRole()
        );
    }

    // ================== LOGIN ==================

    public AuthResponse authenticate(AuthRequest request) {
        authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(
                        request.getEmail(),
                        request.getPassword()
                )
        );

        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.UNAUTHORIZED,
                        "Utilisateur non trouvé"
                ));

        String token = jwtService.generateToken(user);

        return new AuthResponse(
                token,
                user.getFullName(),
                user.getEmail(),
                user.getRole()
        );
    }

    // ================== /auth/me ==================

    public User getCurrentUserFromToken(String token) {
        String email = jwtService.extractUsername(token);

        return userRepository.findByEmail(email)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Utilisateur non trouvé"
                ));
    }

    // ================== UPDATE PROFILE ==================

    public User updateProfile(String token, com.elearnia.dto.UpdateProfileRequest request) {
        User user = getCurrentUserFromToken(token);

        if (request.getFullName() != null && !request.getFullName().trim().isEmpty()) {
            user.setFullName(request.getFullName().trim());
        }

        if (request.getEmail() != null && !request.getEmail().trim().isEmpty()) {
            String newEmail = request.getEmail().trim();
            // Vérifier si l'email est déjà utilisé par un autre utilisateur
            if (!user.getEmail().equals(newEmail) && userRepository.existsByEmail(newEmail)) {
                throw new ResponseStatusException(
                        HttpStatus.CONFLICT,
                        "Cet email est déjà utilisé"
                );
            }
            user.setEmail(newEmail);
        }

        return userRepository.save(user);
    }
}
