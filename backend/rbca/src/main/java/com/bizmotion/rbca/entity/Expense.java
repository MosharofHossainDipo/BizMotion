package com.bizmotion.rbca.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;

@Entity
@Table(name = "expenses")
@Getter @Setter @NoArgsConstructor
public class Expense {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "expense_code", unique = true, nullable = false, length = 50)
    private String expenseCode;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "account_id", nullable = false)
    private Account account;

    @Column(name = "exp_date", nullable = false)
    private LocalDate date;

    @Column(length = 1000)
    private String description;

    @Column(nullable = false, length = 10)
    private String currency = "BDT";

    @Column(nullable = false, precision = 16, scale = 2)
    private BigDecimal amount;

    @Column(length = 150)
    private String category;

    @Column(length = 500)
    private String tags;

    @Column(length = 200)
    private String company;

    @Column(length = 200)
    private String payee;

    @Column(length = 200)
    private String staff;

    @Column(name = "payment_method", length = 100)
    private String paymentMethod;

    @Column(nullable = false, length = 20)
    private String status = "Cleared";

    @Column(name = "reference_no", length = 150)
    private String referenceNo;

    @Column(name = "attachment_name", length = 300)
    private String attachmentName;

    @Column(name = "created_by")
    private Long createdBy;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @PrePersist void onCreate() { createdAt = Instant.now(); }
}
