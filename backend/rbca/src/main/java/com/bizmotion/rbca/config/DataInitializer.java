package com.bizmotion.rbca.config;

import com.bizmotion.rbca.entity.Role;
import com.bizmotion.rbca.entity.Scope;
import com.bizmotion.rbca.repository.RoleRepository;
import com.bizmotion.rbca.repository.ScopeRepository;
import com.bizmotion.rbca.security.RoleScopeCache;
import com.bizmotion.rbca.security.ScopeEnum;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

@Component
public class DataInitializer implements ApplicationRunner {

    @Autowired private JdbcTemplate    jdbc;
    @Autowired private RoleRepository  roleRepo;
    @Autowired private ScopeRepository scopeRepo;
    @Autowired private RoleScopeCache  roleScopeCache;

    private static final List<String> ADMIN_SCOPES = List.of(
        "VIEW_CUSTOMER","CREATE_CUSTOMER","EDIT_CUSTOMER","DELETE_CUSTOMER",
        "VIEW_INVOICE","CREATE_INVOICE","EDIT_INVOICE","DELETE_INVOICE","APPROVE_INVOICE",
        "VIEW_PAYMENT","CREATE_PAYMENT","PROCESS_PAYMENT","REFUND_PAYMENT",
        "VIEW_LEDGER","POST_JOURNAL_ENTRY","CLOSE_PERIOD",
        "VIEW_REPORT","EXPORT_REPORT","GENERATE_REPORT",
        "VIEW_USER","EDIT_USER","DELETE_USER","ASSIGN_ROLE",
        "VIEW_AUDIT_LOG","MANAGE_SETTINGS",
        "VIEW_ACCOUNT","CREATE_ACCOUNT","EDIT_ACCOUNT","DELETE_ACCOUNT",
        "VIEW_DEPOSIT","CREATE_DEPOSIT",
        "VIEW_EXPENSE","CREATE_EXPENSE",
        "VIEW_TRANSFER","CREATE_TRANSFER"



    );

    private static final List<String> ACCOUNTANT_SCOPES = List.of(
        "VIEW_CUSTOMER","CREATE_CUSTOMER","EDIT_CUSTOMER",
        "VIEW_INVOICE","CREATE_INVOICE","VIEW_PAYMENT","CREATE_PAYMENT",
        "VIEW_LEDGER","POST_JOURNAL_ENTRY",
        "VIEW_REPORT","EXPORT_REPORT","GENERATE_REPORT",
        "VIEW_ACCOUNT","CREATE_ACCOUNT","EDIT_ACCOUNT"
    );

    private static final List<String> VIEWER_SCOPES = List.of(
        "VIEW_CUSTOMER","VIEW_INVOICE","VIEW_PAYMENT",
        "VIEW_LEDGER","VIEW_REPORT","VIEW_USER",
        "VIEW_ACCOUNT"
    );

    @Override
    public void run(ApplicationArguments args) {
        grantAllScopesTo("SUPER_ADMIN");
        grantScopes("ADMIN",      ADMIN_SCOPES);
        grantScopes("ACCOUNTANT", ACCOUNTANT_SCOPES);
        grantScopes("VIEWER",     VIEWER_SCOPES);
        roleScopeCache.reload();
        System.out.println("[DataInitializer] All scopes granted and cache reloaded.");
    }

    /** Keeps SUPER_ADMIN permanently in sync with every scope that exists,
     *  including ones added after the initial Flyway seed migration ran.
     *  Flyway migrations only run once, so without this, any newly added
     *  ScopeEnum value would silently never reach SUPER_ADMIN. */
    private void grantAllScopesTo(String roleName) {
        List<String> allScopeNames = Arrays.stream(ScopeEnum.values())
                .map(Enum::name)
                .collect(Collectors.toList());
        grantScopes(roleName, allScopeNames);
    }

    private void grantScopes(String roleName, List<String> scopeNames) {
        Role role = roleRepo.findByRoleName(roleName).orElse(null);
        if (role == null) {
            System.out.println("[DataInitializer] Role not found: " + roleName);
            return;
        }

        for (String scopeName : scopeNames) {
            try {
                ScopeEnum enumVal = ScopeEnum.valueOf(scopeName);
                Scope scope = scopeRepo.findByName(enumVal).orElse(null);
                if (scope == null) {
                    System.out.println("[DataInitializer] Scope not found: " + scopeName);
                    continue;
                }
                Integer exists = jdbc.queryForObject(
                    "SELECT COUNT(*) FROM role_scopes WHERE role_id=? AND scope_id=?",
                    Integer.class, role.getId(), scope.getId()
                );
                if (exists == null || exists == 0) {
                    jdbc.update(
                        "INSERT INTO role_scopes (role_id, scope_id) VALUES (?,?)",
                        role.getId(), scope.getId()
                    );
                    System.out.println("[DataInitializer] Granted " + scopeName + " -> " + roleName);
                }
            } catch (IllegalArgumentException e) {
                System.out.println("[DataInitializer] Unknown scope enum: " + scopeName);
            } catch (Exception e) {
                System.out.println("[DataInitializer] Error granting " + scopeName + ": " + e.getMessage());
            }
        }
    }
}