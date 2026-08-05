package com.bizmotion.rbca.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import java.math.BigDecimal;
import java.time.Instant;

@Getter @AllArgsConstructor
public class AccountDto {
    private Long       id;
    private String     accountCode;
    private String     accountTitle;
    private String     description;
    private String     accountNumber;
    private String     contactPerson;
    private String     phone;
    private String     internetBankingUrl;
    private BigDecimal initialBalanceBdt;
    private BigDecimal initialBalanceUsd;
    private BigDecimal totalDeposits;
    private BigDecimal totalExpenses;
    private BigDecimal totalTransfersIn;
    private BigDecimal totalTransfersOut;
    private BigDecimal currentBalance;
    private String     status;
    private Long       createdBy;
    private Instant    createdAt;
    private Instant    updatedAt;
}
