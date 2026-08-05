package com.bizmotion.rbca.repository;

import com.bizmotion.rbca.entity.Transfer;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.util.List;

@Repository
public interface TransferRepository extends JpaRepository<Transfer, Long> {

    boolean existsByTransferCode(String transferCode);

    @Query("SELECT COALESCE(SUM(t.amount), 0) FROM Transfer t WHERE t.fromAccount.id = :accountId")
    BigDecimal sumOutByAccountId(@Param("accountId") Long accountId);

    @Query("SELECT COALESCE(SUM(t.amount), 0) FROM Transfer t WHERE t.toAccount.id = :accountId")
    BigDecimal sumInByAccountId(@Param("accountId") Long accountId);

    @Query("SELECT DISTINCT t.paymentMethod FROM Transfer t WHERE t.paymentMethod IS NOT NULL ORDER BY t.paymentMethod")
    List<String> findDistinctPaymentMethods();
}
