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
