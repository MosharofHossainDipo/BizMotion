package com.bizmotion.rbca.service;
import com.bizmotion.rbca.dto.ScopeDto;
import com.bizmotion.rbca.entity.*;
import com.bizmotion.rbca.repository.*;
import com.bizmotion.rbca.security.RoleScopeCache;
import com.bizmotion.rbca.security.ScopeEnum;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;
import java.util.List;
import java.util.stream.Collectors;
@Service
public class ScopeService {
    @Autowired private ScopeRepository scopeRepository;
    @Autowired private RoleScopeRepository roleScopeRepository;
    @Autowired private RoleRepository roleRepository;
    @Autowired private RoleScopeCache roleScopeCache;
    public List<ScopeDto> getAllScopes() {
        return scopeRepository.findAll().stream()
                .map(s -> new ScopeDto(s.getId(), s.getName().name()))
                .collect(Collectors.toList());
    }
    @Transactional
    public ScopeDto createScope(String scopeName, Long targetRoleId) {
        ScopeEnum enumValue;
        try { enumValue = ScopeEnum.valueOf(scopeName.toUpperCase()); }
        catch (IllegalArgumentException e) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Unknown scope. Add to ScopeEnum.java first.");
        }
        Scope scope = new Scope();
        scope.setName(enumValue);
        scope = scopeRepository.save(scope);
        Role targetRole = roleRepository.findById(targetRoleId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Role not found"));
        roleScopeRepository.save(new RoleScope(targetRole, scope));
        roleScopeCache.addScopeToRole(targetRole.getRoleName(), scopeName);
        Role superAdmin = roleRepository.findByRoleName("SUPER_ADMIN")
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "SUPER_ADMIN missing"));
        boolean alreadyHasIt = roleScopeRepository.existsById(new RoleScopeId(superAdmin.getId(), scope.getId()));
        if (!alreadyHasIt) {
            roleScopeRepository.save(new RoleScope(superAdmin, scope));
            roleScopeCache.addScopeToRole("SUPER_ADMIN", scopeName);
        }
        return new ScopeDto(scope.getId(), scopeName);
    }
    @Transactional
    public void deleteScope(Long scopeId) {
        Scope scope = scopeRepository.findById(scopeId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Scope not found"));
        scopeRepository.delete(scope);
        roleScopeCache.reload();
    }
}