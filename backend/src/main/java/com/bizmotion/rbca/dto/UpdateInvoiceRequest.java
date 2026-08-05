package com.bizmotion.rbca.dto;

import lombok.Getter;
import lombok.Setter;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

@Getter @Setter
public class UpdateInvoiceRequest {
    private Long customerId;
    private String subject;
    private String billingAddress;
    private String invoiceType;
    private String currency;
    private String paymentTerms;
    private BigDecimal taxPercent;
    private LocalDate invoiceDate;
    private LocalDate dueDate;
    private String notesToCustomer;
    private String internalRemarks;
    private List<CreateInvoiceItemRequest> items;
}