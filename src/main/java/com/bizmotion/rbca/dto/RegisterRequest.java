package com.bizmotion.rbca.dto;
import jakarta.validation.constraints.*;
import lombok.Getter;
import lombok.Setter;
@Getter @Setter
public class RegisterRequest {
    @NotBlank(message = "Username is required")
    @Size(min = 4, message = "Username must be at least 4 characters")
    @Pattern(regexp = "\\S+", message = "Username cannot contain spaces")
    private String username;
    @NotBlank(message = "Email is required")
    @Email(message = "Enter a valid email address")
    private String email;
    @NotBlank(message = "Password is required")
    @Size(min = 6, message = "Password must be at least 6 characters")
    private String password;
    @NotBlank(message = "Please confirm your password")
    private String confirmPassword;
}
