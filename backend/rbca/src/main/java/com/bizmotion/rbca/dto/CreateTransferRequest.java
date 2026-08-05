package com.bizmotion.rbca.dto;

import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;
import java.math.BigDecimal;
import java.time.LocalDate;

@Getter @Setter
public class CreateTransferRequest {
    @NotNull(message = "Source account is required")
    private Long fromAccountId;

    @NotNull(message = "Destination account is required")
    private Long toAccountId;

    @NotNull(message = "Date is required")
    private LocalDate date;

    private String description;
    private String currency = "BDT";

    @NotNull(message = "Amount is required")
    private BigDecimal amount;

    private String tags;
    private String paymentMethod;
    private String referenceNo;
}
