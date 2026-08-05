package com.bizmotion.rbca.dto;

import lombok.Getter;
import lombok.Setter;
import java.math.BigDecimal;

@Getter @Setter
public class UpdateAccountRequest {
    private String accountTitle;
    private String description;
    private String accountNumber;
    private String contactPerson;
    private String phone;
    private String internetBankingUrl;
    private BigDecimal initialBalanceBdt;
    private BigDecimal initialBalanceUsd;
}
