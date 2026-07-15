package com.bizmotion.rbca.controller;
import com.bizmotion.rbca.dto.RoleDto;
import com.bizmotion.rbca.dto.UpdateRoleScopesRequest;
import com.bizmotion.rbca.entity.Role;
import com.bizmotion.rbca.repository.RoleRepository;
import com.bizmotion.rbca.repository.RoleScopeRepository;
import com.bizmotion.rbca.service.RoleService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.Setter;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;
import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/roles")
public class RoleController {

    @Autowired private RoleRepository      roleRepository;
    @Autowired private RoleScopeRepository roleScopeRepository;
    @Autowired private RoleService         roleService;

    @GetMapping
    @PreAuthorize("hasAuthority('VIEW_USER')")
    public ResponseEntity<List<RoleDto>> getAllRoles() {
        return ResponseEntity.ok(roleRepository.findAll().stream()
                .map(r -> new RoleDto(r.getId(), r.getRoleName()))
                .collect(Collectors.toList()));
    }

    @GetMapping("/{id}/scopes")
    @PreAuthorize("hasAuthority('VIEW_USER')")
    public ResponseEntity<List<String>> getRoleScopes(@PathVariable Long id) {
        return ResponseEntity.ok(roleService.getScopeNamesForRole(id));
    }

    @PutMapping("/{id}/scopes")
    @PreAuthorize("hasAuthority('MANAGE_SETTINGS')")
    public ResponseEntity<String> updateRoleScopes(
            @PathVariable Long id,
            @RequestBody @Valid UpdateRoleScopesRequest req) {
        roleService.updateRoleScopes(id, req.getScopeIds());
        return ResponseEntity.ok("Role scopes updated");
    }

    @PostMapping
    @PreAuthorize("hasAuthority('MANAGE_SETTINGS')")
    public ResponseEntity<RoleDto> createRole(@RequestBody @Valid CreateRoleRequest req) {
        if (roleRepository.findByRoleName(req.getRoleName().toUpperCase()).isPresent())
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Role already exists");
        Role role = new Role();
        role.setRoleName(req.getRoleName().toUpperCase().trim());
        role = roleRepository.save(role);
        return ResponseEntity.status(201).body(new RoleDto(role.getId(), role.getRoleName()));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasAuthority('MANAGE_SETTINGS')")
    public ResponseEntity<String> deleteRole(@PathVariable Long id) {
        Role role = roleRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Role not found"));
        String name = role.getRoleName();
        if ("SUPER_ADMIN".equals(name) || "ADMIN".equals(name) || "VIEWER".equals(name) || "ACCOUNTANT".equals(name))
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Cannot delete built-in role: " + name);
        roleScopeRepository.deleteAll(roleScopeRepository.findByRole(role));
        roleRepository.delete(role);
        return ResponseEntity.ok("Role deleted: " + name);
    }

    @PostMapping("/{id}/assign-scope")
    @PreAuthorize("hasAuthority('MANAGE_SETTINGS')")
    public ResponseEntity<String> assignScopeToRole(
            @PathVariable Long id,
            @RequestBody AssignScopeRequest req) {
        roleService.updateRoleScopes(id,
            java.util.List.of(req.getScopeIds().toArray(new Long[0])));
        return ResponseEntity.ok("Scopes assigned to role");
    }

    @Getter @Setter
    public static class CreateRoleRequest {
        @NotBlank(message = "Role name is required")
        private String roleName;
    }

    @Getter @Setter
    public static class AssignScopeRequest {
        private List<Long> scopeIds;
    }
}