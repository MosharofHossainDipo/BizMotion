package com.bizmotion.rbca.service;
import com.bizmotion.rbca.dto.AuthResponse;
import com.bizmotion.rbca.dto.LoginRequest;
import com.bizmotion.rbca.dto.RegisterRequest;
import com.bizmotion.rbca.entity.Role;
import com.bizmotion.rbca.entity.User;
import com.bizmotion.rbca.repository.RoleRepository;
import com.bizmotion.rbca.repository.UserRepository;
import com.bizmotion.rbca.security.JwtUtil;
import com.bizmotion.rbca.security.RoleScopeCache;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;
import java.util.Set;
@Service
public class AuthService {
    @Autowired private UserRepository  userRepository;
    @Autowired private RoleRepository  roleRepository;
    @Autowired private JwtUtil         jwtUtil;
    @Autowired private PasswordEncoder passwordEncoder;
    @Autowired private RoleScopeCache  roleScopeCache;
    public void register(RegisterRequest req) {
        if (!req.getPassword().equals(req.getConfirmPassword()))
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Passwords do not match");
        if (userRepository.existsByUsername(req.getUsername()))
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Username already taken");
        if (userRepository.existsByEmail(req.getEmail()))
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Email already registered");
        Role viewerRole = roleRepository.findByRoleName("VIEWER")
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "Default role not found"));
        User user = new User();
        user.setUsername(req.getUsername());
        user.setEmail(req.getEmail());
        user.setPasswordHash(passwordEncoder.encode(req.getPassword()));
        user.setRole(viewerRole);
        user.setActive(true);
        userRepository.save(user);
    }
    public AuthResponse login(LoginRequest req) {
        User user = userRepository.findByUsername(req.getUsername())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Invalid credentials"));
        if (!passwordEncoder.matches(req.getPassword(), user.getPasswordHash()))
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Invalid credentials");
        if (!user.isActive())
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Account deactivated. Contact your administrator.");
        String      roleName     = user.getRole().getRoleName();
        Set<String> scopes       = roleScopeCache.getScopesForRole(roleName);
        String      accessToken  = jwtUtil.generateAccessToken(user.getUsername(), roleName);
        String      refreshToken = jwtUtil.generateRefreshToken(user.getUsername());
        return new AuthResponse(accessToken, refreshToken, roleName, scopes, user.getUsername(), user.getId());
    }
    public AuthResponse refresh(String refreshToken) {
        if (!jwtUtil.isValid(refreshToken))
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Invalid or expired refresh token");
        String username = jwtUtil.extractUsername(refreshToken);
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "User not found"));
        if (!user.isActive())
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Account deactivated.");
        String      roleName  = user.getRole().getRoleName();
        Set<String> scopes    = roleScopeCache.getScopesForRole(roleName);
        String      newAccess = jwtUtil.generateAccessToken(username, roleName);
        return new AuthResponse(newAccess, refreshToken, roleName, scopes, username, user.getId());
    }
}