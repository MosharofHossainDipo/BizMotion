package com.bizmotion.rbca.repository;
import com.bizmotion.rbca.entity.Scope;
import com.bizmotion.rbca.security.ScopeEnum;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;
@Repository
public interface ScopeRepository extends JpaRepository<Scope, Long> {
    Optional<Scope> findByName(ScopeEnum name);
}
