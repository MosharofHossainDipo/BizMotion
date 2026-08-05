package com.bizmotion.rbca.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import java.util.List;

@Getter @AllArgsConstructor
public class InvoiceImportResult {
    private int totalInvoices;
    private int imported;
    private int duplicates;
    private int invalid;
    private List<String> errors;
}
