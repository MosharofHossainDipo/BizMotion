package com.bizmotion.rbca.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;

@Getter @AllArgsConstructor
public class TransferDto {
    private Long       id;
    private String     transferCode;
    private Long       fromAccountId;
    private String     fromAccountTitle;
    private Long       toAccountId;
    private String     toAccountTitle;
    private LocalDate  date;
    private String     description;
    private String     currency;
    private BigDecimal amount;
    private String     tags;
    private String     paymentMethod;
    private String     referenceNo;
    private Long       createdBy;
    private Instant    createdAt;
}
