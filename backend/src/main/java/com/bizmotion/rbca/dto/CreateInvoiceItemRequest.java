package com.bizmotion.rbca.dto;

import lombok.Getter;
import lombok.Setter;
import java.math.BigDecimal;

@Getter @Setter
public class CreateInvoiceItemRequest {
    private String     description;
    private BigDecimal qty       = BigDecimal.ONE;
    private BigDecimal unitPrice = BigDecimal.ZERO;
}