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
    private String               trackingNumber;
    private String               subject;
    private Long                 customerId;
    private String               customerName;
    private String               billingAddress;
    private String               status;
    private String               invoiceType;
    private String               currency;
    private String               paymentTerms;
    private LocalDate            invoiceDate;
    private LocalDate            dueDate;
    private BigDecimal           taxPercent;
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