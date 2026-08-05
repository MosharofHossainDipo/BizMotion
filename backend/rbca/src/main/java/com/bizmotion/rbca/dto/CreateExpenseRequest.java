package com.bizmotion.rbca.dto;

import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;
import java.math.BigDecimal;
import java.time.LocalDate;

@Getter @Setter
public class CreateExpenseRequest {
    @NotNull(message = "Account is required")
    private Long accountId;

    @NotNull(message = "Date is required")
    private LocalDate date;

    private String description;
    private String currency = "BDT";

    @NotNull(message = "Amount is required")
    private BigDecimal amount;

    private String category;
    private String tags;
    private String company;
    private String payee;
    private String staff;
    private String paymentMethod;
    private String status = "Cleared";
    private String referenceNo;
}
