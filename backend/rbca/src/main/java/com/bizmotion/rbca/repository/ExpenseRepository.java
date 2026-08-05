package com.bizmotion.rbca.repository;

import com.bizmotion.rbca.entity.Expense;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.util.List;

@Repository
public interface ExpenseRepository extends JpaRepository<Expense, Long> {

    boolean existsByExpenseCode(String expenseCode);

    @Query("SELECT COALESCE(SUM(e.amount), 0) FROM Expense e WHERE e.account.id = :accountId")
    BigDecimal sumAmountByAccountId(@Param("accountId") Long accountId);

    @Query("SELECT DISTINCT e.category FROM Expense e WHERE e.category IS NOT NULL ORDER BY e.category")
    List<String> findDistinctCategories();

    @Query("SELECT DISTINCT e.staff FROM Expense e WHERE e.staff IS NOT NULL ORDER BY e.staff")
    List<String> findDistinctStaff();

    @Query("SELECT DISTINCT e.paymentMethod FROM Expense e WHERE e.paymentMethod IS NOT NULL ORDER BY e.paymentMethod")
    List<String> findDistinctPaymentMethods();
}
