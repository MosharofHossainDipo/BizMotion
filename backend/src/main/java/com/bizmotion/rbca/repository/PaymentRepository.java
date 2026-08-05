package com.bizmotion.rbca.repository;

import com.bizmotion.rbca.entity.Payment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.util.List;

@Repository
public interface PaymentRepository extends JpaRepository<Payment, Long> {

    boolean existsByPaymentCode(String paymentCode);

    @Query("SELECT COALESCE(SUM(p.amount), 0) FROM Payment p WHERE p.invoice.id = :invoiceId")
    BigDecimal sumByInvoiceId(@Param("invoiceId") Long invoiceId);

    @Query("SELECT p FROM Payment p WHERE p.invoice.id = :invoiceId ORDER BY p.id DESC")
    List<Payment> findByInvoiceId(@Param("invoiceId") Long invoiceId);
}
