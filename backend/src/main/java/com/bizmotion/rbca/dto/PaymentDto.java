package com.bizmotion.rbca.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;

@Getter @AllArgsConstructor
public class PaymentDto {
    private Long       id;
    private String     paymentCode;
    private Long       invoiceId;
    private String     invoiceNumber;
    private Long       customerId;
    private String     customerName;
    private Long       accountId;
    private String     accountTitle;
    private LocalDate  date;
    private BigDecimal amount;
    private String     currency;
    private String     category;
    private String     payer;
    private String     paymentMethod;
    private String     referenceNo;
    private String     description;
    private String     notes;
    private Long       createdBy;
    private Instant    createdAt;
}
