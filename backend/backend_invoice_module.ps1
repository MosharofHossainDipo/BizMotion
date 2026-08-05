# ---- Backend: V7__create_invoices_table.sql ----
$content = @'
CREATE TABLE invoices (
    id                 NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    invoice_number     VARCHAR2(50)   NOT NULL,
    customer_id        NUMBER         NOT NULL,
    billing_address    VARCHAR2(1000),
    status             VARCHAR2(20)   DEFAULT 'Draft' NOT NULL,
    invoice_type       VARCHAR2(20)   DEFAULT 'Onetime' NOT NULL,
    currency           VARCHAR2(10)   DEFAULT 'BDT' NOT NULL,
    payment_terms      VARCHAR2(100),
    invoice_date       DATE           NOT NULL,
    due_date           DATE,
    subtotal           NUMBER(14,2)   DEFAULT 0 NOT NULL,
    tax_total          NUMBER(14,2)   DEFAULT 0 NOT NULL,
    grand_total        NUMBER(14,2)   DEFAULT 0 NOT NULL,
    notes_to_customer  VARCHAR2(2000),
    internal_remarks   VARCHAR2(2000),
    created_by         NUMBER,
    created_at         TIMESTAMP      DEFAULT SYSTIMESTAMP NOT NULL,
    updated_at         TIMESTAMP      DEFAULT SYSTIMESTAMP NOT NULL,
    CONSTRAINT inv_number_uk UNIQUE (invoice_number),
    CONSTRAINT fk_invoice_customer FOREIGN KEY (customer_id) REFERENCES customers(id)
);

CREATE TABLE invoice_items (
    id              NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    invoice_id      NUMBER         NOT NULL,
    description     VARCHAR2(2000),
    qty             NUMBER(12,2)   DEFAULT 1 NOT NULL,
    unit_price      NUMBER(14,2)   DEFAULT 0 NOT NULL,
    discount_value  NUMBER(14,2)   DEFAULT 0 NOT NULL,
    discount_type   VARCHAR2(10)   DEFAULT 'percent' NOT NULL,
    tax_percent     NUMBER(5,2)    DEFAULT 0 NOT NULL,
    line_total      NUMBER(14,2)   DEFAULT 0 NOT NULL,
    sort_order      NUMBER         DEFAULT 0 NOT NULL,
    CONSTRAINT fk_item_invoice FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON DELETE CASCADE
);
'@
Write-ProjectFile "rbca/rbca/src/main/resources/db/migration/V7__create_invoices_table.sql" $content

# ---- Backend: InvoiceItem.java ----
$content = @'
package com.bizmotion.rbca.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import java.math.BigDecimal;

@Entity
@Table(name = "invoice_items")
@Getter @Setter @NoArgsConstructor
public class InvoiceItem {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "invoice_id", nullable = false)
    private Invoice invoice;

    @Column(length = 2000)
    private String description;

    @Column(nullable = false, precision = 12, scale = 2)
    private BigDecimal qty = BigDecimal.ONE;

    @Column(name = "unit_price", nullable = false, precision = 14, scale = 2)
    private BigDecimal unitPrice = BigDecimal.ZERO;

    @Column(name = "discount_value", nullable = false, precision = 14, scale = 2)
    private BigDecimal discountValue = BigDecimal.ZERO;

    @Column(name = "discount_type", nullable = false, length = 10)
    private String discountType = "percent"; // "percent" | "amount"

    @Column(name = "tax_percent", nullable = false, precision = 5, scale = 2)
    private BigDecimal taxPercent = BigDecimal.ZERO;

    @Column(name = "line_total", nullable = false, precision = 14, scale = 2)
    private BigDecimal lineTotal = BigDecimal.ZERO;

    @Column(name = "sort_order", nullable = false)
    private Integer sortOrder = 0;
}
'@
Write-ProjectFile "rbca/rbca/src/main/java/com/bizmotion/rbca/entity/InvoiceItem.java" $content

# ---- Backend: Invoice.java ----
$content = @'
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
'@
Write-ProjectFile "rbca/rbca/src/main/java/com/bizmotion/rbca/entity/Invoice.java" $content

# ---- Backend: InvoiceItemDto.java ----
$content = @'
package com.bizmotion.rbca.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import java.math.BigDecimal;

@Getter @AllArgsConstructor
public class InvoiceItemDto {
    private Long       id;
    private String     description;
    private BigDecimal qty;
    private BigDecimal unitPrice;
    private BigDecimal discountValue;
    private String     discountType;
    private BigDecimal taxPercent;
    private BigDecimal lineTotal;
    private Integer    sortOrder;
}
'@
Write-ProjectFile "rbca/rbca/src/main/java/com/bizmotion/rbca/dto/InvoiceItemDto.java" $content

# ---- Backend: InvoiceDto.java ----
$content = @'
package com.bizmotion.rbca.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;

@Getter @AllArgsConstructor
public class InvoiceDto {
    private Long                id;
    private String               invoiceNumber;
    private Long                 customerId;
    private String               customerName;
    private String               billingAddress;
    private String               status;
    private String               invoiceType;
    private String               currency;
    private String               paymentTerms;
    private LocalDate            invoiceDate;
    private LocalDate            dueDate;
    private BigDecimal           subtotal;
    private BigDecimal           taxTotal;
    private BigDecimal           grandTotal;
    private String               notesToCustomer;
    private String               internalRemarks;
    private Long                 createdBy;
    private Instant              createdAt;
    private Instant              updatedAt;
    private List<InvoiceItemDto> items;
}
'@
Write-ProjectFile "rbca/rbca/src/main/java/com/bizmotion/rbca/dto/InvoiceDto.java" $content

# ---- Backend: CreateInvoiceItemRequest.java ----
$content = @'
package com.bizmotion.rbca.dto;

import lombok.Getter;
import lombok.Setter;
import java.math.BigDecimal;

@Getter @Setter
public class CreateInvoiceItemRequest {
    private String     description;
    private BigDecimal qty           = BigDecimal.ONE;
    private BigDecimal unitPrice     = BigDecimal.ZERO;
    private BigDecimal discountValue = BigDecimal.ZERO;
    private String     discountType  = "percent";
    private BigDecimal taxPercent    = BigDecimal.ZERO;
}
'@
Write-ProjectFile "rbca/rbca/src/main/java/com/bizmotion/rbca/dto/CreateInvoiceItemRequest.java" $content

# ---- Backend: CreateInvoiceRequest.java ----
$content = @'
package com.bizmotion.rbca.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;
import java.time.LocalDate;
import java.util.List;

@Getter @Setter
public class CreateInvoiceRequest {
    @NotNull(message = "Customer is required")
    private Long customerId;

    private String billingAddress;
    private String invoiceType   = "Onetime";
    private String currency      = "BDT";
    private String prefix        = "INV-";
    private String paymentTerms  = "Due On Receipt";

    @NotNull(message = "Invoice date is required")
    private LocalDate invoiceDate;
    private LocalDate dueDate;

    private String notesToCustomer;
    private String internalRemarks;

    @Valid
    private List<CreateInvoiceItemRequest> items;
}
'@
Write-ProjectFile "rbca/rbca/src/main/java/com/bizmotion/rbca/dto/CreateInvoiceRequest.java" $content

# ---- Backend: UpdateInvoiceRequest.java ----
$content = @'
package com.bizmotion.rbca.dto;

import lombok.Getter;
import lombok.Setter;
import java.time.LocalDate;
import java.util.List;

@Getter @Setter
public class UpdateInvoiceRequest {
    private Long customerId;
    private String billingAddress;
    private String invoiceType;
    private String currency;
    private String paymentTerms;
    private LocalDate invoiceDate;
    private LocalDate dueDate;
    private String notesToCustomer;
    private String internalRemarks;
    private List<CreateInvoiceItemRequest> items;
}
'@
Write-ProjectFile "rbca/rbca/src/main/java/com/bizmotion/rbca/dto/UpdateInvoiceRequest.java" $content

# ---- Backend: InvoiceRepository.java ----
$content = @'
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
'@
Write-ProjectFile "rbca/rbca/src/main/java/com/bizmotion/rbca/repository/InvoiceRepository.java" $content

# ---- Backend: InvoiceService.java ----
$content = @'
package com.bizmotion.rbca.service;

import com.bizmotion.rbca.dto.*;
import com.bizmotion.rbca.entity.Customer;
import com.bizmotion.rbca.entity.Invoice;
import com.bizmotion.rbca.entity.InvoiceItem;
import com.bizmotion.rbca.repository.CustomerRepository;
import com.bizmotion.rbca.repository.InvoiceRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Year;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class InvoiceService {

    @Autowired private InvoiceRepository  repo;
    @Autowired private CustomerRepository customerRepo;

    public List<InvoiceDto> getAll() {
        return repo.findAll().stream()
                .sorted((a, b) -> b.getId().compareTo(a.getId())) // newest first
                .map(this::toDto).collect(Collectors.toList());
    }

    public InvoiceDto getById(Long id) {
        return toDto(repo.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Invoice not found")));
    }

    @Transactional
    public InvoiceDto create(CreateInvoiceRequest req, boolean finalize, Long callerId) {
        Customer customer = customerRepo.findById(req.getCustomerId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Customer not found"));

        Invoice inv = new Invoice();
        inv.setInvoiceNumber(generateInvoiceNumber(req.getPrefix()));
        inv.setCustomer(customer);
        inv.setBillingAddress(req.getBillingAddress());
        inv.setInvoiceType(req.getInvoiceType() != null ? req.getInvoiceType() : "Onetime");
        inv.setCurrency(req.getCurrency() != null ? req.getCurrency() : "BDT");
        inv.setPaymentTerms(req.getPaymentTerms());
        inv.setInvoiceDate(req.getInvoiceDate());
        inv.setDueDate(req.getDueDate());
        inv.setNotesToCustomer(req.getNotesToCustomer());
        inv.setInternalRemarks(req.getInternalRemarks());
        inv.setStatus(finalize ? "Unpaid" : "Draft");
        inv.setCreatedBy(callerId);

        applyItems(inv, req.getItems());
        recalculateTotals(inv);

        return toDto(repo.save(inv));
    }

    @Transactional
    public InvoiceDto update(Long id, UpdateInvoiceRequest req) {
        Invoice inv = repo.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Invoice not found"));

        if (req.getCustomerId() != null) {
            Customer customer = customerRepo.findById(req.getCustomerId())
                    .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Customer not found"));
            inv.setCustomer(customer);
        }
        if (req.getBillingAddress()  != null) inv.setBillingAddress(req.getBillingAddress());
        if (req.getInvoiceType()     != null) inv.setInvoiceType(req.getInvoiceType());
        if (req.getCurrency()        != null) inv.setCurrency(req.getCurrency());
        if (req.getPaymentTerms()    != null) inv.setPaymentTerms(req.getPaymentTerms());
        if (req.getInvoiceDate()     != null) inv.setInvoiceDate(req.getInvoiceDate());
        if (req.getDueDate()         != null) inv.setDueDate(req.getDueDate());
        if (req.getNotesToCustomer() != null) inv.setNotesToCustomer(req.getNotesToCustomer());
        if (req.getInternalRemarks() != null) inv.setInternalRemarks(req.getInternalRemarks());

        if (req.getItems() != null) {
            inv.getItems().clear();
            applyItems(inv, req.getItems());
        }
        recalculateTotals(inv);

        return toDto(repo.save(inv));
    }

    @Transactional
    public void setStatus(Long id, String status) {
        List<String> allowed = List.of("Draft", "Unpaid", "Partially Paid", "Paid", "Cancelled");
        if (!allowed.contains(status)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invalid status: " + status);
        }
        Invoice inv = repo.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Invoice not found"));
        inv.setStatus(status);
        repo.save(inv);
    }

    @Transactional
    public void delete(Long id) {
        if (!repo.existsById(id))
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Invoice not found");
        repo.deleteById(id);
    }

    // ---- helpers ----

    private void applyItems(Invoice inv, List<CreateInvoiceItemRequest> itemReqs) {
        if (itemReqs == null || itemReqs.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "At least one line item is required");
        }
        int order = 0;
        for (CreateInvoiceItemRequest ir : itemReqs) {
            InvoiceItem item = new InvoiceItem();
            item.setInvoice(inv);
            item.setDescription(ir.getDescription());
            item.setQty(nz(ir.getQty(), BigDecimal.ONE));
            item.setUnitPrice(nz(ir.getUnitPrice(), BigDecimal.ZERO));
            item.setDiscountValue(nz(ir.getDiscountValue(), BigDecimal.ZERO));
            item.setDiscountType("amount".equalsIgnoreCase(ir.getDiscountType()) ? "amount" : "percent");
            item.setTaxPercent(nz(ir.getTaxPercent(), BigDecimal.ZERO));
            item.setSortOrder(order++);
            item.setLineTotal(computeLineTotal(item));
            inv.getItems().add(item);
        }
    }

    /** Recomputes every line total plus invoice subtotal/tax/grand total server-side.
     *  Client-submitted totals are never trusted. */
    private void recalculateTotals(Invoice inv) {
        BigDecimal subtotal = BigDecimal.ZERO;
        BigDecimal taxTotal = BigDecimal.ZERO;

        for (InvoiceItem item : inv.getItems()) {
            BigDecimal lineBase = item.getQty().multiply(item.getUnitPrice());
            BigDecimal discountAmt = "amount".equals(item.getDiscountType())
                    ? item.getDiscountValue()
                    : lineBase.multiply(item.getDiscountValue()).divide(BigDecimal.valueOf(100), 4, RoundingMode.HALF_UP);
            BigDecimal afterDiscount = lineBase.subtract(discountAmt).max(BigDecimal.ZERO);
            BigDecimal lineTax = afterDiscount.multiply(item.getTaxPercent()).divide(BigDecimal.valueOf(100), 4, RoundingMode.HALF_UP);

            item.setLineTotal(afterDiscount.add(lineTax).setScale(2, RoundingMode.HALF_UP));
            subtotal = subtotal.add(afterDiscount);
            taxTotal = taxTotal.add(lineTax);
        }

        inv.setSubtotal(subtotal.setScale(2, RoundingMode.HALF_UP));
        inv.setTaxTotal(taxTotal.setScale(2, RoundingMode.HALF_UP));
        inv.setGrandTotal(subtotal.add(taxTotal).setScale(2, RoundingMode.HALF_UP));
    }

    private BigDecimal computeLineTotal(InvoiceItem item) {
        BigDecimal lineBase = item.getQty().multiply(item.getUnitPrice());
        BigDecimal discountAmt = "amount".equals(item.getDiscountType())
                ? item.getDiscountValue()
                : lineBase.multiply(item.getDiscountValue()).divide(BigDecimal.valueOf(100), 4, RoundingMode.HALF_UP);
        BigDecimal afterDiscount = lineBase.subtract(discountAmt).max(BigDecimal.ZERO);
        BigDecimal lineTax = afterDiscount.multiply(item.getTaxPercent()).divide(BigDecimal.valueOf(100), 4, RoundingMode.HALF_UP);
        return afterDiscount.add(lineTax).setScale(2, RoundingMode.HALF_UP);
    }

    private BigDecimal nz(BigDecimal v, BigDecimal fallback) { return v != null ? v : fallback; }

    /** Uses MAX(id)+1 rather than COUNT(*) so a deleted invoice can never cause
     *  a duplicate-number collision (see the same bug already flagged in CustomerService). */
    private String generateInvoiceNumber(String prefix) {
        String p = (prefix == null || prefix.isBlank()) ? "INV-" : prefix;
        int year = Year.now().getValue();
        long nextSeq = repo.findMaxId() + 1;
        String candidate;
        do {
            candidate = String.format("%s%d-%04d", p, year, nextSeq);
            nextSeq++;
        } while (repo.existsByInvoiceNumber(candidate));
        return candidate;
    }

    private InvoiceDto toDto(Invoice inv) {
        List<InvoiceItemDto> items = inv.getItems().stream()
                .map(i -> new InvoiceItemDto(i.getId(), i.getDescription(), i.getQty(), i.getUnitPrice(),
                        i.getDiscountValue(), i.getDiscountType(), i.getTaxPercent(), i.getLineTotal(), i.getSortOrder()))
                .collect(Collectors.toList());

        return new InvoiceDto(
                inv.getId(), inv.getInvoiceNumber(),
                inv.getCustomer().getId(), inv.getCustomer().getName(),
                inv.getBillingAddress(), inv.getStatus(), inv.getInvoiceType(), inv.getCurrency(),
                inv.getPaymentTerms(), inv.getInvoiceDate(), inv.getDueDate(),
                inv.getSubtotal(), inv.getTaxTotal(), inv.getGrandTotal(),
                inv.getNotesToCustomer(), inv.getInternalRemarks(),
                inv.getCreatedBy(), inv.getCreatedAt(), inv.getUpdatedAt(), items
        );
    }
}
'@
Write-ProjectFile "rbca/rbca/src/main/java/com/bizmotion/rbca/service/InvoiceService.java" $content

# ---- Backend: InvoiceController.java ----
$content = @'
package com.bizmotion.rbca.controller;

import com.bizmotion.rbca.dto.CreateInvoiceRequest;
import com.bizmotion.rbca.dto.InvoiceDto;
import com.bizmotion.rbca.dto.UpdateInvoiceRequest;
import com.bizmotion.rbca.service.InvoiceService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/invoices")
public class InvoiceController {

    @Autowired
    private InvoiceService invoiceService;

    @GetMapping
    @PreAuthorize("hasAuthority('VIEW_INVOICE')")
    public ResponseEntity<List<InvoiceDto>> getAll() {
        return ResponseEntity.ok(invoiceService.getAll());
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasAuthority('VIEW_INVOICE')")
    public ResponseEntity<InvoiceDto> getById(@PathVariable Long id) {
        return ResponseEntity.ok(invoiceService.getById(id));
    }

    @PostMapping
    @PreAuthorize("hasAuthority('CREATE_INVOICE')")
    public ResponseEntity<InvoiceDto> create(
            @RequestBody @Valid CreateInvoiceRequest req,
            @RequestParam(defaultValue = "false") boolean finalize) {
        return ResponseEntity.status(201).body(invoiceService.create(req, finalize, null));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAuthority('EDIT_INVOICE')")
    public ResponseEntity<InvoiceDto> update(
            @PathVariable Long id,
            @RequestBody UpdateInvoiceRequest req) {
        return ResponseEntity.ok(invoiceService.update(id, req));
    }

    @PutMapping("/{id}/status")
    @PreAuthorize("hasAuthority('EDIT_INVOICE')")
    public ResponseEntity<String> setStatus(
            @PathVariable Long id,
            @RequestBody Map<String, String> body) {
        invoiceService.setStatus(id, body.get("status"));
        return ResponseEntity.ok("Status updated");
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasAuthority('DELETE_INVOICE')")
    public ResponseEntity<String> delete(@PathVariable Long id) {
        invoiceService.delete(id);
        return ResponseEntity.ok("Invoice deleted");
    }
}
'@
Write-ProjectFile "rbca/rbca/src/main/java/com/bizmotion/rbca/controller/InvoiceController.java" $content
