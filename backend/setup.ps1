# BizMotion RBAC - Create all project files automatically
# Run this from D:\rbca\rbca in VS Code terminal

$base = "src\main\java\com\bizmotion\rbca"
$res  = "src\main\resources"

Write-Host "Creating all project files..." -ForegroundColor Cyan

# ── V1__create_tables.sql ─────────────────────────────────────
@'
CREATE TABLE roles (
    id        NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    role_name VARCHAR2(50) NOT NULL UNIQUE
);
CREATE TABLE scopes (
    id   NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR2(50) NOT NULL UNIQUE
);
CREATE TABLE users (
    id            NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    username      VARCHAR2(50)  NOT NULL UNIQUE,
    email         VARCHAR2(100) NOT NULL UNIQUE,
    password_hash VARCHAR2(255) NOT NULL,
    role_id       NUMBER        NOT NULL,
    CONSTRAINT fk_user_role FOREIGN KEY (role_id) REFERENCES roles(id)
);
CREATE TABLE role_scopes (
    role_id  NUMBER NOT NULL,
    scope_id NUMBER NOT NULL,
    CONSTRAINT pk_role_scopes PRIMARY KEY (role_id, scope_id),
    CONSTRAINT fk_rs_role  FOREIGN KEY (role_id)  REFERENCES roles(id),
    CONSTRAINT fk_rs_scope FOREIGN KEY (scope_id) REFERENCES scopes(id)
);
'@ | Set-Content "$res\db\migration\V1__create_tables.sql" -Encoding UTF8
Write-Host "  [OK] V1__create_tables.sql" -ForegroundColor Green

# ── V2__seed_roles_and_scopes.sql ────────────────────────────
@'
INSERT INTO roles (role_name) VALUES ('SUPER_ADMIN');
INSERT INTO roles (role_name) VALUES ('ADMIN');
INSERT INTO roles (role_name) VALUES ('ACCOUNTANT');
INSERT INTO roles (role_name) VALUES ('VIEWER');
INSERT INTO scopes (name) VALUES ('CREATE_USER');
INSERT INTO scopes (name) VALUES ('EDIT_USER');
INSERT INTO scopes (name) VALUES ('DELETE_USER');
INSERT INTO scopes (name) VALUES ('VIEW_USER');
INSERT INTO scopes (name) VALUES ('ASSIGN_ROLE');
INSERT INTO scopes (name) VALUES ('CREATE_INVOICE');
INSERT INTO scopes (name) VALUES ('EDIT_INVOICE');
INSERT INTO scopes (name) VALUES ('DELETE_INVOICE');
INSERT INTO scopes (name) VALUES ('VIEW_INVOICE');
INSERT INTO scopes (name) VALUES ('APPROVE_INVOICE');
INSERT INTO scopes (name) VALUES ('CREATE_PAYMENT');
INSERT INTO scopes (name) VALUES ('VIEW_PAYMENT');
INSERT INTO scopes (name) VALUES ('PROCESS_PAYMENT');
INSERT INTO scopes (name) VALUES ('REFUND_PAYMENT');
INSERT INTO scopes (name) VALUES ('VIEW_LEDGER');
INSERT INTO scopes (name) VALUES ('POST_JOURNAL_ENTRY');
INSERT INTO scopes (name) VALUES ('CLOSE_PERIOD');
INSERT INTO scopes (name) VALUES ('VIEW_REPORT');
INSERT INTO scopes (name) VALUES ('EXPORT_REPORT');
INSERT INTO scopes (name) VALUES ('GENERATE_REPORT');
INSERT INTO scopes (name) VALUES ('CREATE_CUSTOMER');
INSERT INTO scopes (name) VALUES ('EDIT_CUSTOMER');
INSERT INTO scopes (name) VALUES ('VIEW_CUSTOMER');
INSERT INTO scopes (name) VALUES ('DELETE_CUSTOMER');
INSERT INTO scopes (name) VALUES ('VIEW_AUDIT_LOG');
INSERT INTO scopes (name) VALUES ('MANAGE_SETTINGS');
INSERT INTO role_scopes (role_id, scope_id)
    SELECT r.id, s.id FROM roles r, scopes s WHERE r.role_name = 'SUPER_ADMIN';
INSERT INTO role_scopes (role_id, scope_id)
    SELECT r.id, s.id FROM roles r, scopes s
    WHERE r.role_name = 'ADMIN'
    AND s.name IN ('CREATE_USER','EDIT_USER','DELETE_USER','VIEW_USER','ASSIGN_ROLE','VIEW_AUDIT_LOG','MANAGE_SETTINGS');
INSERT INTO role_scopes (role_id, scope_id)
    SELECT r.id, s.id FROM roles r, scopes s
    WHERE r.role_name = 'ACCOUNTANT'
    AND s.name IN ('CREATE_INVOICE','EDIT_INVOICE','DELETE_INVOICE','VIEW_INVOICE','APPROVE_INVOICE',
        'CREATE_PAYMENT','VIEW_PAYMENT','PROCESS_PAYMENT','REFUND_PAYMENT',
        'VIEW_LEDGER','POST_JOURNAL_ENTRY','CLOSE_PERIOD',
        'VIEW_REPORT','EXPORT_REPORT','GENERATE_REPORT',
        'CREATE_CUSTOMER','EDIT_CUSTOMER','VIEW_CUSTOMER','DELETE_CUSTOMER','VIEW_USER');
INSERT INTO role_scopes (role_id, scope_id)
    SELECT r.id, s.id FROM roles r, scopes s
    WHERE r.role_name = 'VIEWER'
    AND s.name IN ('VIEW_INVOICE','VIEW_PAYMENT','VIEW_LEDGER','VIEW_REPORT','VIEW_CUSTOMER','VIEW_USER');
COMMIT;
'@ | Set-Content "$res\db\migration\V2__seed_roles_and_scopes.sql" -Encoding UTF8
Write-Host "  [OK] V2__seed_roles_and_scopes.sql" -ForegroundColor Green

# ── V3__seed_super_admin_user.sql ────────────────────────────
@'
INSERT INTO users (username, email, password_hash, role_id)
SELECT 'super_admin', 'admin@bizmotion.com',
       '$2a$12$tQCeHWFWTQOKYXgCXmLXeO7YX8vQZk3pGpJjX4qGxU5m1NrFdK7Wy',
       id FROM roles WHERE role_name = 'SUPER_ADMIN';
COMMIT;
'@ | Set-Content "$res\db\migration\V3__seed_super_admin_user.sql" -Encoding UTF8
Write-Host "  [OK] V3__seed_super_admin_user.sql" -ForegroundColor Green

# ── ScopeEnum.java ───────────────────────────────────────────
@'
package com.bizmotion.rbca.security;
public enum ScopeEnum {
    CREATE_USER, EDIT_USER, DELETE_USER, VIEW_USER, ASSIGN_ROLE,
    CREATE_INVOICE, EDIT_INVOICE, DELETE_INVOICE, VIEW_INVOICE, APPROVE_INVOICE,
    CREATE_PAYMENT, VIEW_PAYMENT, PROCESS_PAYMENT, REFUND_PAYMENT,
    VIEW_LEDGER, POST_JOURNAL_ENTRY, CLOSE_PERIOD,
    VIEW_REPORT, EXPORT_REPORT, GENERATE_REPORT,
    CREATE_CUSTOMER, EDIT_CUSTOMER, VIEW_CUSTOMER, DELETE_CUSTOMER,
    VIEW_AUDIT_LOG, MANAGE_SETTINGS
}
'@ | Set-Content "$base\security\ScopeEnum.java" -Encoding UTF8
Write-Host "  [OK] ScopeEnum.java" -ForegroundColor Green

# ── Role.java ────────────────────────────────────────────────
@'
package com.bizmotion.rbca.entity;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
@Entity
@Table(name = "roles")
@Getter @Setter @NoArgsConstructor
public class Role {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Column(name = "role_name", unique = true, nullable = false, length = 50)
    private String roleName;
}
'@ | Set-Content "$base\entity\Role.java" -Encoding UTF8
Write-Host "  [OK] Role.java" -ForegroundColor Green

# ── Scope.java ───────────────────────────────────────────────
@'
package com.bizmotion.rbca.entity;
import com.bizmotion.rbca.security.ScopeEnum;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
@Entity
@Table(name = "scopes")
@Getter @Setter @NoArgsConstructor
public class Scope {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Enumerated(EnumType.STRING)
    @Column(name = "name", unique = true, nullable = false, length = 50)
    private ScopeEnum name;
}
'@ | Set-Content "$base\entity\Scope.java" -Encoding UTF8
Write-Host "  [OK] Scope.java" -ForegroundColor Green

# ── User.java ────────────────────────────────────────────────
@'
package com.bizmotion.rbca.entity;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
@Entity
@Table(name = "users")
@Getter @Setter @NoArgsConstructor
public class User {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Column(unique = true, nullable = false, length = 50)
    private String username;
    @Column(unique = true, nullable = false, length = 100)
    private String email;
    @Column(name = "password_hash", nullable = false, length = 255)
    private String passwordHash;
    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "role_id", nullable = false)
    private Role role;
}
'@ | Set-Content "$base\entity\User.java" -Encoding UTF8
Write-Host "  [OK] User.java" -ForegroundColor Green

# ── RoleScopeId.java ─────────────────────────────────────────
@'
package com.bizmotion.rbca.entity;
import jakarta.persistence.Embeddable;
import lombok.*;
import java.io.Serializable;
@Embeddable
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @EqualsAndHashCode
public class RoleScopeId implements Serializable {
    private Long roleId;
    private Long scopeId;
}
'@ | Set-Content "$base\entity\RoleScopeId.java" -Encoding UTF8
Write-Host "  [OK] RoleScopeId.java" -ForegroundColor Green

# ── RoleScope.java ───────────────────────────────────────────
@'
package com.bizmotion.rbca.entity;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
@Entity
@Table(name = "role_scopes")
@Getter @Setter @NoArgsConstructor
public class RoleScope {
    @EmbeddedId
    private RoleScopeId id;
    @ManyToOne(fetch = FetchType.EAGER)
    @MapsId("roleId")
    @JoinColumn(name = "role_id")
    private Role role;
    @ManyToOne(fetch = FetchType.EAGER)
    @MapsId("scopeId")
    @JoinColumn(name = "scope_id")
    private Scope scope;
    public RoleScope(Role role, Scope scope) {
        this.role = role;
        this.scope = scope;
        this.id = new RoleScopeId(role.getId(), scope.getId());
    }
}
'@ | Set-Content "$base\entity\RoleScope.java" -Encoding UTF8
Write-Host "  [OK] RoleScope.java" -ForegroundColor Green

# ── UserRepository.java ──────────────────────────────────────
@'
package com.bizmotion.rbca.repository;
import com.bizmotion.rbca.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;
@Repository
public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByUsername(String username);
    Optional<User> findByEmail(String email);
    boolean existsByUsername(String username);
    boolean existsByEmail(String email);
}
'@ | Set-Content "$base\repository\UserRepository.java" -Encoding UTF8
Write-Host "  [OK] UserRepository.java" -ForegroundColor Green

# ── RoleRepository.java ──────────────────────────────────────
@'
package com.bizmotion.rbca.repository;
import com.bizmotion.rbca.entity.Role;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;
@Repository
public interface RoleRepository extends JpaRepository<Role, Long> {
    Optional<Role> findByRoleName(String roleName);
}
'@ | Set-Content "$base\repository\RoleRepository.java" -Encoding UTF8
Write-Host "  [OK] RoleRepository.java" -ForegroundColor Green

# ── ScopeRepository.java ─────────────────────────────────────
@'
package com.bizmotion.rbca.repository;
import com.bizmotion.rbca.entity.Scope;
import com.bizmotion.rbca.security.ScopeEnum;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;
@Repository
public interface ScopeRepository extends JpaRepository<Scope, Long> {
    Optional<Scope> findByName(ScopeEnum name);
}
'@ | Set-Content "$base\repository\ScopeRepository.java" -Encoding UTF8
Write-Host "  [OK] ScopeRepository.java" -ForegroundColor Green

# ── RoleScopeRepository.java ─────────────────────────────────
@'
package com.bizmotion.rbca.repository;
import com.bizmotion.rbca.entity.Role;
import com.bizmotion.rbca.entity.RoleScope;
import com.bizmotion.rbca.entity.RoleScopeId;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
@Repository
public interface RoleScopeRepository extends JpaRepository<RoleScope, RoleScopeId> {
    List<RoleScope> findByRole(Role role);
}
'@ | Set-Content "$base\repository\RoleScopeRepository.java" -Encoding UTF8
Write-Host "  [OK] RoleScopeRepository.java" -ForegroundColor Green

# ── RoleScopeCache.java ──────────────────────────────────────
@'
package com.bizmotion.rbca.security;
import com.bizmotion.rbca.entity.RoleScope;
import com.bizmotion.rbca.repository.RoleScopeRepository;
import jakarta.annotation.PostConstruct;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
@Component
public class RoleScopeCache {
    private final ConcurrentHashMap<String, Set<String>> cache = new ConcurrentHashMap<>();
    @Autowired
    private RoleScopeRepository roleScopeRepository;
    @PostConstruct
    public void loadAll() {
        cache.clear();
        List<RoleScope> all = roleScopeRepository.findAll();
        for (RoleScope rs : all) {
            String roleName  = rs.getRole().getRoleName();
            String scopeName = rs.getScope().getName().name();
            cache.computeIfAbsent(roleName, k -> new HashSet<>()).add(scopeName);
        }
        System.out.println("RoleScopeCache loaded: " + cache.size() + " roles cached.");
    }
    public Set<String> getScopesForRole(String roleName) {
        return cache.getOrDefault(roleName, Set.of());
    }
    public void addScopeToRole(String roleName, String scopeName) {
        cache.computeIfAbsent(roleName, k -> new HashSet<>()).add(scopeName);
    }
    public void reload() { loadAll(); }
}
'@ | Set-Content "$base\security\RoleScopeCache.java" -Encoding UTF8
Write-Host "  [OK] RoleScopeCache.java" -ForegroundColor Green

# ── JwtUtil.java ─────────────────────────────────────────────
@'
package com.bizmotion.rbca.security;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.io.Decoders;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import javax.crypto.SecretKey;
import java.util.Date;
@Component
public class JwtUtil {
    @Value("${jwt.secret}")           private String secret;
    @Value("${jwt.access-expiry-ms}") private long   accessExpiryMs;
    @Value("${jwt.refresh-expiry-ms}") private long  refreshExpiryMs;
    public String generateAccessToken(String username, String role) {
        return Jwts.builder()
                .subject(username)
                .claim("role", role)
                .issuedAt(new Date())
                .expiration(new Date(System.currentTimeMillis() + accessExpiryMs))
                .signWith(getSigningKey())
                .compact();
    }
    public String generateRefreshToken(String username) {
        return Jwts.builder()
                .subject(username)
                .claim("type", "refresh")
                .issuedAt(new Date())
                .expiration(new Date(System.currentTimeMillis() + refreshExpiryMs))
                .signWith(getSigningKey())
                .compact();
    }
    public String extractUsername(String token) { return parseClaims(token).getSubject(); }
    public String extractRole(String token)     { return (String) parseClaims(token).get("role"); }
    public boolean isValid(String token) {
        try { parseClaims(token); return true; } catch (Exception e) { return false; }
    }
    private Claims parseClaims(String token) {
        return Jwts.parser().verifyWith(getSigningKey()).build()
                   .parseSignedClaims(token).getPayload();
    }
    private SecretKey getSigningKey() {
        return Keys.hmacShaKeyFor(Decoders.BASE64.decode(secret));
    }
}
'@ | Set-Content "$base\security\JwtUtil.java" -Encoding UTF8
Write-Host "  [OK] JwtUtil.java" -ForegroundColor Green

# ── JwtAuthenticationFilter.java ────────────────────────────
@'
package com.bizmotion.rbca.security;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;
@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {
    @Autowired private JwtUtil        jwtUtil;
    @Autowired private RoleScopeCache roleScopeCache;
    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain)
            throws ServletException, IOException {
        String authHeader = request.getHeader("Authorization");
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            filterChain.doFilter(request, response); return;
        }
        String token = authHeader.substring(7);
        if (!jwtUtil.isValid(token)) {
            filterChain.doFilter(request, response); return;
        }
        String username = jwtUtil.extractUsername(token);
        String role     = jwtUtil.extractRole(token);
        Set<String> scopes = roleScopeCache.getScopesForRole(role);
        List<SimpleGrantedAuthority> authorities = new ArrayList<>();
        for (String scope : scopes) {
            authorities.add(new SimpleGrantedAuthority(scope));
        }
        authorities.add(new SimpleGrantedAuthority("ROLE_" + role));
        UsernamePasswordAuthenticationToken auth =
                new UsernamePasswordAuthenticationToken(username, null, authorities);
        SecurityContextHolder.getContext().setAuthentication(auth);
        filterChain.doFilter(request, response);
    }
}
'@ | Set-Content "$base\security\JwtAuthenticationFilter.java" -Encoding UTF8
Write-Host "  [OK] JwtAuthenticationFilter.java" -ForegroundColor Green

# ── SecurityConfig.java ──────────────────────────────────────
@'
package com.bizmotion.rbca.config;
import com.bizmotion.rbca.security.JwtAuthenticationFilter;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
@Configuration
@EnableWebSecurity
@EnableMethodSecurity
public class SecurityConfig {
    @Autowired private JwtAuthenticationFilter jwtFilter;
    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        return http
                .csrf(csrf -> csrf.disable())
                .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers("/api/auth/**").permitAll()
                        .anyRequest().authenticated()
                )
                .addFilterBefore(jwtFilter, UsernamePasswordAuthenticationFilter.class)
                .build();
    }
    @Bean
    public PasswordEncoder passwordEncoder() { return new BCryptPasswordEncoder(); }
}
'@ | Set-Content "$base\config\SecurityConfig.java" -Encoding UTF8
Write-Host "  [OK] SecurityConfig.java" -ForegroundColor Green

# ── DTOs ─────────────────────────────────────────────────────
@'
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
    @Size(min = 8, message = "Password must be at least 8 characters")
    private String password;
    @NotBlank(message = "Please confirm your password")
    private String confirmPassword;
}
'@ | Set-Content "$base\dto\RegisterRequest.java" -Encoding UTF8

@'
package com.bizmotion.rbca.dto;
import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.Setter;
@Getter @Setter
public class LoginRequest {
    @NotBlank(message = "Username is required")
    private String username;
    @NotBlank(message = "Password is required")
    private String password;
}
'@ | Set-Content "$base\dto\LoginRequest.java" -Encoding UTF8

@'
package com.bizmotion.rbca.dto;
import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.Setter;
@Getter @Setter
public class RefreshRequest {
    @NotBlank(message = "Refresh token is required")
    private String refreshToken;
}
'@ | Set-Content "$base\dto\RefreshRequest.java" -Encoding UTF8

@'
package com.bizmotion.rbca.dto;
import lombok.AllArgsConstructor;
import lombok.Getter;
@Getter @AllArgsConstructor
public class AuthResponse {
    private String accessToken;
    private String refreshToken;
    private String role;
}
'@ | Set-Content "$base\dto\AuthResponse.java" -Encoding UTF8

@'
package com.bizmotion.rbca.dto;
import lombok.AllArgsConstructor;
import lombok.Getter;
@Getter @AllArgsConstructor
public class UserDto {
    private Long   id;
    private String username;
    private String email;
    private String roleName;
}
'@ | Set-Content "$base\dto\UserDto.java" -Encoding UTF8

@'
package com.bizmotion.rbca.dto;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;
@Getter @Setter
public class AssignRoleRequest {
    @NotNull(message = "Role ID is required")
    private Long roleId;
}
'@ | Set-Content "$base\dto\AssignRoleRequest.java" -Encoding UTF8
Write-Host "  [OK] All 6 DTOs" -ForegroundColor Green

# ── AuthService.java ─────────────────────────────────────────
@'
package com.bizmotion.rbca.service;
import com.bizmotion.rbca.dto.AuthResponse;
import com.bizmotion.rbca.dto.LoginRequest;
import com.bizmotion.rbca.dto.RegisterRequest;
import com.bizmotion.rbca.entity.Role;
import com.bizmotion.rbca.entity.User;
import com.bizmotion.rbca.repository.RoleRepository;
import com.bizmotion.rbca.repository.UserRepository;
import com.bizmotion.rbca.security.JwtUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;
@Service
public class AuthService {
    @Autowired private UserRepository  userRepository;
    @Autowired private RoleRepository  roleRepository;
    @Autowired private JwtUtil         jwtUtil;
    @Autowired private PasswordEncoder passwordEncoder;
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
        userRepository.save(user);
    }
    public AuthResponse login(LoginRequest req) {
        User user = userRepository.findByUsername(req.getUsername())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Invalid credentials"));
        if (!passwordEncoder.matches(req.getPassword(), user.getPasswordHash()))
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Invalid credentials");
        String roleName     = user.getRole().getRoleName();
        String accessToken  = jwtUtil.generateAccessToken(user.getUsername(), roleName);
        String refreshToken = jwtUtil.generateRefreshToken(user.getUsername());
        return new AuthResponse(accessToken, refreshToken, roleName);
    }
    public AuthResponse refresh(String refreshToken) {
        if (!jwtUtil.isValid(refreshToken))
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Invalid or expired refresh token");
        String username = jwtUtil.extractUsername(refreshToken);
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "User not found"));
        String newAccess = jwtUtil.generateAccessToken(username, user.getRole().getRoleName());
        return new AuthResponse(newAccess, refreshToken, user.getRole().getRoleName());
    }
}
'@ | Set-Content "$base\service\AuthService.java" -Encoding UTF8
Write-Host "  [OK] AuthService.java" -ForegroundColor Green

# ── AuthController.java ──────────────────────────────────────
@'
package com.bizmotion.rbca.controller;
import com.bizmotion.rbca.dto.AuthResponse;
import com.bizmotion.rbca.dto.LoginRequest;
import com.bizmotion.rbca.dto.RefreshRequest;
import com.bizmotion.rbca.dto.RegisterRequest;
import com.bizmotion.rbca.service.AuthService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
@RestController
@RequestMapping("/api/auth")
public class AuthController {
    @Autowired private AuthService authService;
    @PostMapping("/register")
    public ResponseEntity<String> register(@RequestBody @Valid RegisterRequest req) {
        authService.register(req);
        return ResponseEntity.status(201).body("Registration successful");
    }
    @PostMapping("/login")
    public ResponseEntity<AuthResponse> login(@RequestBody @Valid LoginRequest req) {
        return ResponseEntity.ok(authService.login(req));
    }
    @PostMapping("/refresh")
    public ResponseEntity<AuthResponse> refresh(@RequestBody @Valid RefreshRequest req) {
        return ResponseEntity.ok(authService.refresh(req.getRefreshToken()));
    }
}
'@ | Set-Content "$base\controller\AuthController.java" -Encoding UTF8
Write-Host "  [OK] AuthController.java" -ForegroundColor Green

# ── UserController.java ──────────────────────────────────────
@'
package com.bizmotion.rbca.controller;
import com.bizmotion.rbca.dto.AssignRoleRequest;
import com.bizmotion.rbca.dto.UserDto;
import com.bizmotion.rbca.entity.Role;
import com.bizmotion.rbca.entity.User;
import com.bizmotion.rbca.repository.RoleRepository;
import com.bizmotion.rbca.repository.UserRepository;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;
import java.util.List;
import java.util.stream.Collectors;
@RestController
@RequestMapping("/api/users")
public class UserController {
    @Autowired private UserRepository userRepository;
    @Autowired private RoleRepository roleRepository;
    @GetMapping
    @PreAuthorize("hasAuthority('VIEW_USER')")
    public ResponseEntity<List<UserDto>> getAllUsers() {
        List<UserDto> users = userRepository.findAll().stream()
                .map(u -> new UserDto(u.getId(), u.getUsername(), u.getEmail(), u.getRole().getRoleName()))
                .collect(Collectors.toList());
        return ResponseEntity.ok(users);
    }
    @PutMapping("/{id}/role")
    @PreAuthorize("hasAuthority('ASSIGN_ROLE')")
    public ResponseEntity<String> assignRole(@PathVariable Long id, @RequestBody @Valid AssignRoleRequest req) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "User not found"));
        Role role = roleRepository.findById(req.getRoleId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Role not found"));
        user.setRole(role);
        userRepository.save(user);
        return ResponseEntity.ok("Role updated to " + role.getRoleName());
    }
}
'@ | Set-Content "$base\controller\UserController.java" -Encoding UTF8
Write-Host "  [OK] UserController.java" -ForegroundColor Green

# ── GlobalExceptionHandler.java ──────────────────────────────
@'
package com.bizmotion.rbca.exception;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.server.ResponseStatusException;
import java.util.HashMap;
import java.util.Map;
@RestControllerAdvice
public class GlobalExceptionHandler {
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Map<String, String>> handleValidation(MethodArgumentNotValidException ex) {
        Map<String, String> errors = new HashMap<>();
        for (FieldError e : ex.getBindingResult().getFieldErrors())
            errors.put(e.getField(), e.getDefaultMessage());
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(errors);
    }
    @ExceptionHandler(ResponseStatusException.class)
    public ResponseEntity<Map<String, String>> handleStatus(ResponseStatusException ex) {
        Map<String, String> error = new HashMap<>();
        error.put("error", ex.getReason());
        return ResponseEntity.status(ex.getStatusCode()).body(error);
    }
    @ExceptionHandler(Exception.class)
    public ResponseEntity<Map<String, String>> handleGeneral(Exception ex) {
        Map<String, String> error = new HashMap<>();
        error.put("error", "An unexpected error occurred");
        ex.printStackTrace();
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(error);
    }
}
'@ | Set-Content "$base\exception\GlobalExceptionHandler.java" -Encoding UTF8
Write-Host "  [OK] GlobalExceptionHandler.java" -ForegroundColor Green

Write-Host ""
Write-Host "All files created successfully!" -ForegroundColor Cyan
Write-Host "Now run: mvn spring-boot:run" -ForegroundColor Yellow