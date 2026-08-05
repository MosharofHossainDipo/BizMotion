package com.bizmotion.rbca.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;

@Entity
@Table(name = "payments")
@Getter @Setter @NoArgsConstructor
public class Payment {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "payment_code", unique = true, nullable = false, length = 50)
    private String paymentCode;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "invoice_id", nullable = false)
    private Invoice invoice;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "customer_id", nullable = false)
    private Customer customer;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "account_id", nullable = false)
    private Account account;

    @Column(name = "pay_date", nullable = false)
    private LocalDate date;

    @Column(nullable = false, precision = 16, scale = 2)
    private BigDecimal amount;

    @Column(nullable = false, length = 10)
    private String currency = "BDT";

    @Column(length = 150)
    private String category;

    @Column(length = 200)
    private String payer;

    @Column(name = "payment_method", length = 100)
    private String paymentMethod;

    @Column(name = "reference_no", length = 150)
    private String referenceNo;

    @Column(length = 1000)
    private String description;

    @Column(length = 2000)
    private String notes;

    /** Traceability link to the Deposit this payment automatically created. */
    @Column(name = "deposit_id")
    private Long depositId;

    @Column(name = "created_by")
    private Long createdBy;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @PrePersist void onCreate() { createdAt = Instant.now(); }
}
