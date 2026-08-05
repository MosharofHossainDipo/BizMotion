package com.bizmotion.rbca.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;

@Entity
@Table(name = "transfers")
@Getter @Setter @NoArgsConstructor
public class Transfer {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "transfer_code", unique = true, nullable = false, length = 50)
    private String transferCode;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "from_account_id", nullable = false)
    private Account fromAccount;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "to_account_id", nullable = false)
    private Account toAccount;

    @Column(name = "xfer_date", nullable = false)
    private LocalDate date;

    @Column(length = 1000)
    private String description;

    @Column(nullable = false, length = 10)
    private String currency = "BDT";

    @Column(nullable = false, precision = 16, scale = 2)
    private BigDecimal amount;

    @Column(length = 500)
    private String tags;

    @Column(name = "payment_method", length = 100)
    private String paymentMethod;

    @Column(name = "reference_no", length = 150)
    private String referenceNo;

    @Column(name = "created_by")
    private Long createdBy;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @PrePersist void onCreate() { createdAt = Instant.now(); }
}
