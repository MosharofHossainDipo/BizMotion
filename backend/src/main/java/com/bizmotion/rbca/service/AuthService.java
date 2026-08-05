package com.bizmotion.rbca.service;

import com.bizmotion.rbca.dto.*;
import com.bizmotion.rbca.entity.Role;
import com.bizmotion.rbca.entity.Scope;
import com.bizmotion.rbca.entity.User;
import com.bizmotion.rbca.repository.RoleRepository;
import com.bizmotion.rbca.repository.ScopeRepository;
import com.bizmotion.rbca.repository.UserRepository;
import com.bizmotion.rbca.security.JwtUtil;
import com.bizmotion.rbca.security.RoleScopeCache;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.Set;
import java.util.stream.Collectors;

@Service
public class AuthService {

    @Autowired private UserRepository  userRepository;
    @Autowired private RoleRepository  roleRepository;
    @Autowired private ScopeRepository scopeRepository;
    @Autowired private JwtUtil         jwtUtil;
    @Autowired private RoleScopeCache  roleScopeCache;

    private final BCryptPasswordEncoder passwordEncoder = new BCryptPasswordEncoder();

    // ── Register ──────────────────────────────────────────
    @Transactional
    public String register(RegisterRequest req) {
        if (userRepository.findByUsername(req.getUsername()).isPresent())
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Username already taken");
        if (userRepository.findByEmail(req.getEmail()).isPresent())
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Email already registered");

        Role viewerRole = roleRepository.findByRoleName("VIEWER")
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "VIEWER role not found"));

        User user = new User();
        user.setUsername(req.getUsername());
        user.setEmail(req.getEmail());
        user.setPasswordHash(passwordEncoder.encode(req.getPassword()));
        user.setRole(viewerRole);
        user.setActive(true);
        userRepository.save(user);
        return "User registered successfully";
    }

    // ── Login ─────────────────────────────────────────────
    public AuthResponse login(LoginRequest req) {
        User user = userRepository.findByUsername(req.getUsername())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Invalid credentials"));

        if (!user.isActive())
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Account is inactive");

        if (!passwordEncoder.matches(req.getPassword(), user.getPasswordHash()))
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Invalid credentials");

        String role         = user.getRole().getRoleName();
        String accessToken  = jwtUtil.generateAccessToken(user.getUsername(), role);
        String refreshToken = jwtUtil.generateRefreshToken(user.getUsername());

        Set<String> scopes = roleScopeCache.getScopesForRole(role);

        return new AuthResponse(
                accessToken, refreshToken, role,
                scopes, user.getUsername(), user.getId()
        );
    }

    // ── Refresh ───────────────────────────────────────────
    public AuthResponse refresh(RefreshRequest req) {
        String token = req.getRefreshToken();

        if (!jwtUtil.isTokenValid(token))
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Invalid or expired refresh token");

        String username = jwtUtil.extractUsername(token);

        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "User not found"));

        if (!user.isActive())
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Account is inactive");

        String role        = user.getRole().getRoleName();
        String newAccess   = jwtUtil.generateAccessToken(username, role);
        String newRefresh  = jwtUtil.generateRefreshToken(username);
        Set<String> scopes = roleScopeCache.getScopesForRole(role);

        return new AuthResponse(newAccess, newRefresh, role, scopes, username, user.getId());
    }
}