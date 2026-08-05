package com.bizmotion.rbca.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import java.math.BigDecimal;
import java.time.LocalDate;

@Getter @AllArgsConstructor
public class TransactionDto {
    private String     transactionId;
    private LocalDate  date;
    private Long       accountId;
    private String     accountTitle;
    private String     company;
    private String     contact;
    private String     category;
    private String     type;
    private String     description;
    private BigDecimal debit;
    private BigDecimal credit;
    private String     paymentMethod;
    private String     staff;
    private String     currency;
}
