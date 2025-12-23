package com.elearnia.dto;

import com.elearnia.model.Role;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class RegisterRequest {

    @NotBlank
    private String fullName;

    @Email
    @NotBlank
    private String email;

    @NotBlank
    private String password;

    private Role role = Role.LEARNER;

    private String biography;
    private String level;
    private String goals;
}

