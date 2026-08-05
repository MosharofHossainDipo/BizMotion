package com.bizmotion.rbca.dto;

import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;
import java.math.BigDecimal;
import java.time.LocalDate;

@Getter @Setter
public class CreatePaymentRequest {
    @NotNull(message = "Account is required")
    private Long accountId;

    @NotNull(message = "Payment date is required")
    private LocalDate date;

    @NotNull(message = "Amount is required")
    private BigDecimal amount;

    private String currency = "BDT";
    private String category;
    private String payer;
    private String paymentMethod;
    private String referenceNo;
    private String description;
    private String notes;
}
