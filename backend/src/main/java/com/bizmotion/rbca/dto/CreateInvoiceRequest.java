package com.bizmotion.rbca.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

@Getter @Setter
public class CreateInvoiceRequest {
    @NotNull(message = "Customer is required")
    private Long customerId;

    /** Descriptive title shown as the big heading on the PDF. */
    private String subject;

    private String billingAddress;
    private String invoiceType   = "Onetime";
    private String currency      = "BDT";
    private String prefix        = "INV-";
    private String paymentTerms  = "Due On Receipt";

    /** Single invoice-wide tax rate applied to the subtotal. */
    private BigDecimal taxPercent = BigDecimal.ZERO;

    @NotNull(message = "Invoice date is required")
    private LocalDate invoiceDate;
    private LocalDate dueDate;

    private String notesToCustomer;
    private String internalRemarks;

    @Valid
    private List<CreateInvoiceItemRequest> items;
}