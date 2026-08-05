package com.bizmotion.rbca.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;

@Getter @AllArgsConstructor
public class DepositDto {
    private Long       id;
    private String     depositCode;
    private Long       accountId;
    private String     accountTitle;
    private LocalDate  date;
    private String     description;
    private String     currency;
    private BigDecimal amount;
    private String     category;
    private String     tags;
    private String     company;
    private String     payer;
    private String     staff;
    private String     paymentMethod;
    private String     referenceNo;
    private Long       createdBy;
    private Instant    createdAt;
}
