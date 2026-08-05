package com.bizmotion.rbca.repository;

import com.bizmotion.rbca.entity.Account;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface AccountRepository extends JpaRepository<Account, Long> {
    boolean existsByAccountTitleIgnoreCase(String accountTitle);
    Optional<Account> findByAccountTitleIgnoreCase(String accountTitle);

    @Query("SELECT a.accountCode FROM Account a WHERE a.accountCode LIKE CONCAT(:prefix, '%')")
    List<String> findCodesWithPrefix(@Param("prefix") String prefix);
}
