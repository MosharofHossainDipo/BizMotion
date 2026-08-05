package com.bizmotion.rbca.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import java.math.BigDecimal;
import java.time.Instant;

@Entity
@Table(name = "accounts")
@Getter @Setter @NoArgsConstructor
public class Account {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "account_code", unique = true, nullable = false, length = 50)
    private String accountCode;

    @Column(name = "account_title", nullable = false, length = 200)
    private String accountTitle;

    @Column(length = 1000)
    private String description;

    @Column(name = "account_number", length = 100)
    private String accountNumber;

    @Column(name = "contact_person", length = 200)
    private String contactPerson;

    @Column(length = 30)
    private String phone;

    @Column(name = "internet_banking_url", length = 300)
    private String internetBankingUrl;

    @Column(name = "initial_balance_bdt", nullable = false, precision = 16, scale = 2)
    private BigDecimal initialBalanceBdt = BigDecimal.ZERO;

    @Column(name = "initial_balance_usd", nullable = false, precision = 16, scale = 2)
    private BigDecimal initialBalanceUsd = BigDecimal.ZERO;

    @Column(name = "owner_id")
    private Long ownerId;

    @Column(nullable = false, length = 20)
    private String status = "Active";

    @Column(name = "created_by")
    private Long createdBy;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @PrePersist void onCreate() { createdAt = Instant.now(); updatedAt = Instant.now(); }
    @PreUpdate  void onUpdate() { updatedAt = Instant.now(); }
}
