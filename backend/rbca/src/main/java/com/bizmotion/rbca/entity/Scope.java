package com.bizmotion.rbca.entity;
import com.bizmotion.rbca.security.ScopeEnum;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
@Entity
@Table(name = "scopes")
@Getter @Setter @NoArgsConstructor
public class Scope {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Enumerated(EnumType.STRING)
    @Column(name = "name", unique = true, nullable = false, length = 50)
    private ScopeEnum name;
}
