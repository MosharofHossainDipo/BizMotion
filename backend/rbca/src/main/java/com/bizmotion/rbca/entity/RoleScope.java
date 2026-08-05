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
