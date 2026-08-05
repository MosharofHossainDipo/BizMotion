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
