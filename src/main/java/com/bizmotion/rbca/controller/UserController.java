package com.bizmotion.rbca.controller;
import com.bizmotion.rbca.dto.AssignRoleRequest;
import com.bizmotion.rbca.dto.UserDto;
import com.bizmotion.rbca.entity.Role;
import com.bizmotion.rbca.entity.User;
import com.bizmotion.rbca.repository.RoleRepository;
import com.bizmotion.rbca.repository.UserRepository;
import com.bizmotion.rbca.security.JwtUtil;
import jakarta.servlet.http.HttpServletRequest;
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
    @Autowired private JwtUtil jwtUtil;
    @GetMapping
    @PreAuthorize("hasAuthority('VIEW_USER')")
    public ResponseEntity<List<UserDto>> getAllUsers(HttpServletRequest request) {
        String token = request.getHeader("Authorization").substring(7);
        String callerRole = jwtUtil.extractRole(token);
        List<UserDto> users = userRepository.findAll().stream()
                .filter(u -> {
                    String uRole = u.getRole().getRoleName();
                    if ("ADMIN".equals(callerRole) && "SUPER_ADMIN".equals(uRole)) return false;
                    return true;
                })
                .map(u -> new UserDto(u.getId(), u.getUsername(), u.getEmail(),
                        u.getRole().getRoleName(), u.getRole().getId(), u.isActive()))
                .collect(Collectors.toList());
        return ResponseEntity.ok(users);
    }
    @GetMapping("/roles-for-admin")
    @PreAuthorize("hasAuthority('ASSIGN_ROLE')")
    public ResponseEntity<List<?>> getRolesForCaller(HttpServletRequest request) {
        String token = request.getHeader("Authorization").substring(7);
        String callerRole = jwtUtil.extractRole(token);
        List<?> roles = roleRepository.findAll().stream()
                .filter(r -> {
                    if ("ADMIN".equals(callerRole) && "SUPER_ADMIN".equals(r.getRoleName())) return false;
                    return true;
                })
                .map(r -> new com.bizmotion.rbca.dto.RoleDto(r.getId(), r.getRoleName()))
                .collect(Collectors.toList());
        return ResponseEntity.ok(roles);
    }
    @PutMapping("/{id}/role")
    @PreAuthorize("hasAuthority('ASSIGN_ROLE')")
    public ResponseEntity<String> assignRole(@PathVariable Long id,
            @RequestBody @Valid AssignRoleRequest req, HttpServletRequest request) {
        String token = request.getHeader("Authorization").substring(7);
        String callerRole = jwtUtil.extractRole(token);
        User user = userRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "User not found"));
        if ("ADMIN".equals(callerRole) && "SUPER_ADMIN".equals(user.getRole().getRoleName()))
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Cannot modify SUPER_ADMIN");
        Role role = roleRepository.findById(req.getRoleId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Role not found"));
        if ("ADMIN".equals(callerRole) && "SUPER_ADMIN".equals(role.getRoleName()))
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Cannot assign SUPER_ADMIN role");
        user.setRole(role);
        userRepository.save(user);
        return ResponseEntity.ok("Role updated to " + role.getRoleName());
    }
    @PutMapping("/{id}/status")
    @PreAuthorize("hasAuthority('EDIT_USER')")
    public ResponseEntity<String> setUserStatus(@PathVariable Long id,
            @RequestBody StatusRequest req, HttpServletRequest request) {
        String token = request.getHeader("Authorization").substring(7);
        String callerRole = jwtUtil.extractRole(token);
        User user = userRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "User not found"));
        if ("ADMIN".equals(callerRole) && "SUPER_ADMIN".equals(user.getRole().getRoleName()))
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Cannot modify SUPER_ADMIN");
        user.setActive(req.isActive());
        userRepository.save(user);
        return ResponseEntity.ok(req.isActive() ? "User activated" : "User deactivated");
    }
    @DeleteMapping("/{id}")
    @PreAuthorize("hasAuthority('DELETE_USER')")
    public ResponseEntity<String> deleteUser(@PathVariable Long id, HttpServletRequest request) {
        String token = request.getHeader("Authorization").substring(7);
        String callerRole = jwtUtil.extractRole(token);
        User user = userRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "User not found"));
        if ("ADMIN".equals(callerRole) && "SUPER_ADMIN".equals(user.getRole().getRoleName()))
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Cannot delete SUPER_ADMIN");
        userRepository.deleteById(id);
        return ResponseEntity.ok("User deleted");
    }
    public static class StatusRequest {
        private boolean active;
        public boolean isActive() { return active; }
        public void setActive(boolean active) { this.active = active; }
    }
}