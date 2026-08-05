package com.bizmotion.rbca.repository;

import com.bizmotion.rbca.entity.Invoice;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

@Repository
public interface InvoiceRepository extends JpaRepository<Invoice, Long> {

    boolean existsByInvoiceNumber(String invoiceNumber);

    @Query("SELECT COALESCE(MAX(i.id), 0) FROM Invoice i")
    Long findMaxId();
}