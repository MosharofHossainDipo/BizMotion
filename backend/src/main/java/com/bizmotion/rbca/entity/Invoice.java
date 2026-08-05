package com.bizmotion.rbca.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "invoices")
@Getter @Setter @NoArgsConstructor
public class Invoice {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "invoice_number", unique = true, nullable = false, length = 50)
    private String invoiceNumber;

    /** Backend-generated identifier printed as "Tracking No:" on the PDF —
     *  separate from invoiceNumber, set right after the first save once the
     *  id is known. */
    @Column(name = "tracking_number", length = 50)
    private String trackingNumber;

    /** User-entered descriptive title shown as the big heading on the PDF,
     *  e.g. "SFA Monthly Bill for February 2026 (PO No-4600000483)". */
    @Column(length = 500)
    private String subject;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "customer_id", nullable = false)
    private Customer customer;

    @Column(name = "billing_address", length = 1000)
    private String billingAddress;

    @Column(nullable = false, length = 20)
    private String status = "Draft"; // Draft | Unpaid | Partially Paid | Paid | Cancelled

    @Column(name = "invoice_type", nullable = false, length = 20)
    private String invoiceType = "Onetime"; // Onetime | Recurring

    @Column(nullable = false, length = 10)
    private String currency = "BDT";

    @Column(name = "payment_terms", length = 100)
    private String paymentTerms;

    @Column(name = "invoice_date", nullable = false)
    private LocalDate invoiceDate;

    @Column(name = "due_date")
    private LocalDate dueDate;

    /** Single invoice-wide tax rate, applied to the subtotal. */
    @Column(name = "tax_percent", nullable = false, precision = 5, scale = 2)
    private BigDecimal taxPercent = BigDecimal.ZERO;

    @Column(nullable = false, precision = 14, scale = 2)
    private BigDecimal subtotal = BigDecimal.ZERO;

    @Column(name = "tax_total", nullable = false, precision = 14, scale = 2)
    private BigDecimal taxTotal = BigDecimal.ZERO;

    @Column(name = "grand_total", nullable = false, precision = 14, scale = 2)
    private BigDecimal grandTotal = BigDecimal.ZERO;

    @Column(name = "notes_to_customer", length = 2000)
    private String notesToCustomer;

    @Column(name = "internal_remarks", length = 2000)
    private String internalRemarks;

    @Column(name = "created_by")
    private Long createdBy;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @OneToMany(mappedBy = "invoice", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.EAGER)
    private List<InvoiceItem> items = new ArrayList<>();

    @PrePersist void onCreate() { createdAt = Instant.now(); updatedAt = Instant.now(); }
    @PreUpdate  void onUpdate() { updatedAt = Instant.now(); }
}