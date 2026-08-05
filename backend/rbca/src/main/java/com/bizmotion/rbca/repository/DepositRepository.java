package com.bizmotion.rbca.repository;

import com.bizmotion.rbca.entity.Deposit;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.util.List;

@Repository
public interface DepositRepository extends JpaRepository<Deposit, Long> {

    boolean existsByDepositCode(String depositCode);

    @Query("SELECT COALESCE(SUM(d.amount), 0) FROM Deposit d WHERE d.account.id = :accountId")
    BigDecimal sumAmountByAccountId(@Param("accountId") Long accountId);

    @Query("SELECT DISTINCT d.category FROM Deposit d WHERE d.category IS NOT NULL ORDER BY d.category")
    List<String> findDistinctCategories();

    @Query("SELECT DISTINCT d.company FROM Deposit d WHERE d.company IS NOT NULL ORDER BY d.company")
    List<String> findDistinctCompanies();

    @Query("SELECT DISTINCT d.payer FROM Deposit d WHERE d.payer IS NOT NULL ORDER BY d.payer")
    List<String> findDistinctPayers();

    @Query("SELECT DISTINCT d.staff FROM Deposit d WHERE d.staff IS NOT NULL ORDER BY d.staff")
    List<String> findDistinctStaff();

    @Query("SELECT DISTINCT d.paymentMethod FROM Deposit d WHERE d.paymentMethod IS NOT NULL ORDER BY d.paymentMethod")
    List<String> findDistinctPaymentMethods();
}
