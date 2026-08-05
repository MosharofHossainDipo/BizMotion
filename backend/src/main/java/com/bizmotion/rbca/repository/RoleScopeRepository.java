package com.bizmotion.rbca.repository;
import com.bizmotion.rbca.entity.Role;
import com.bizmotion.rbca.entity.RoleScope;
import com.bizmotion.rbca.entity.RoleScopeId;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
@Repository
public interface RoleScopeRepository extends JpaRepository<RoleScope, RoleScopeId> {
    List<RoleScope> findByRole(Role role);
}
