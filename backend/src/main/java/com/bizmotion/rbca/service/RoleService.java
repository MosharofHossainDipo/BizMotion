package com.bizmotion.rbca.service;
import com.bizmotion.rbca.entity.*;
import com.bizmotion.rbca.repository.*;
import com.bizmotion.rbca.security.RoleScopeCache;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;
import java.util.List;
import java.util.stream.Collectors;
@Service
public class RoleService {
    @Autowired private RoleRepository roleRepository;
    @Autowired private ScopeRepository scopeRepository;
    @Autowired private RoleScopeRepository roleScopeRepository;
    @Autowired private RoleScopeCache roleScopeCache;
    public List<String> getScopeNamesForRole(Long roleId) {
        Role role = roleRepository.findById(roleId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Role not found"));
        return roleScopeRepository.findByRole(role).stream()
                .map(rs -> rs.getScope().getName().name())
                .collect(Collectors.toList());
    }
    @Transactional
    public void updateRoleScopes(Long roleId, List<Long> newScopeIds) {
        Role role = roleRepository.findById(roleId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Role not found"));
        roleScopeRepository.deleteAll(roleScopeRepository.findByRole(role));
        Role superAdmin = roleRepository.findByRoleName("SUPER_ADMIN")
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "SUPER_ADMIN missing"));
        for (Long scopeId : newScopeIds) {
            Scope scope = scopeRepository.findById(scopeId)
                    .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Scope not found: " + scopeId));
            roleScopeRepository.save(new RoleScope(role, scope));
            boolean superAdminHasIt = roleScopeRepository.existsById(new RoleScopeId(superAdmin.getId(), scope.getId()));
            if (!superAdminHasIt && !role.getRoleName().equals("SUPER_ADMIN"))
                roleScopeRepository.save(new RoleScope(superAdmin, scope));
        }
        roleScopeCache.reload();
    }
}