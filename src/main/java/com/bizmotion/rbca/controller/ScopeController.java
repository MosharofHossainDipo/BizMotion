package com.bizmotion.rbca.controller;
import com.bizmotion.rbca.dto.CreateScopeRequest;
import com.bizmotion.rbca.dto.ScopeDto;
import com.bizmotion.rbca.service.ScopeService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import java.util.List;
@RestController
@RequestMapping("/api/scopes")
public class ScopeController {
    @Autowired private ScopeService scopeService;
    @GetMapping
    @PreAuthorize("hasAuthority('VIEW_USER')")
    public ResponseEntity<List<ScopeDto>> getAllScopes() {
        return ResponseEntity.ok(scopeService.getAllScopes());
    }
    @PostMapping
    @PreAuthorize("hasAuthority('MANAGE_SETTINGS')")
    public ResponseEntity<ScopeDto> createScope(@RequestBody @Valid CreateScopeRequest req) {
        return ResponseEntity.status(201).body(scopeService.createScope(req.getScopeName(), req.getTargetRoleId()));
    }
    @DeleteMapping("/{id}")
    @PreAuthorize("hasAuthority('MANAGE_SETTINGS')")
    public ResponseEntity<String> deleteScope(@PathVariable Long id) {
        scopeService.deleteScope(id);
        return ResponseEntity.ok("Scope deleted");
    }
}