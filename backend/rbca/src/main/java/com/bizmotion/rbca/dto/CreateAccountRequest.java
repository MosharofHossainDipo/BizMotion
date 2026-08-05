package com.bizmotion.rbca.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.Setter;
import java.math.BigDecimal;

@Getter @Setter
public class CreateAccountRequest {
    @NotBlank(message = "Account title is required")
    private String accountTitle;

    private String description;
    private String accountNumber;
    private String contactPerson;
    private String phone;
    private String internetBankingUrl;
    private BigDecimal initialBalanceBdt = BigDecimal.ZERO;
    private BigDecimal initialBalanceUsd = BigDecimal.ZERO;
}
