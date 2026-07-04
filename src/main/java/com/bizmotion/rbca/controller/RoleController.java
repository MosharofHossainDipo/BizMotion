package com.bizmotion.rbca.controller;
import com.bizmotion.rbca.dto.RoleDto;
import com.bizmotion.rbca.dto.UpdateRoleScopesRequest;
import com.bizmotion.rbca.repository.RoleRepository;
import com.bizmotion.rbca.service.RoleService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import java.util.List;
import java.util.stream.Collectors;
@RestController
@RequestMapping("/api/roles")
public class RoleController {
    @Autowired private RoleRepository roleRepository;
    @Autowired private RoleService roleService;
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
    public ResponseEntity<String> updateRoleScopes(@PathVariable Long id, @RequestBody @Valid UpdateRoleScopesRequest req) {
        roleService.updateRoleScopes(id, req.getScopeIds());
        return ResponseEntity.ok("Role scopes updated");
    }
}