package com.bizmotion.rbca.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import java.math.BigDecimal;

@Getter @AllArgsConstructor
public class InvoiceItemDto {
    private Long       id;
    private String     description;
    private BigDecimal qty;
    private BigDecimal unitPrice;
    private BigDecimal lineTotal;
    private Integer    sortOrder;
}