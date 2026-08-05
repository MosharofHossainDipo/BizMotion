package com.bizmotion.rbca.controller;

import com.bizmotion.rbca.dto.TransactionDto;
import com.bizmotion.rbca.service.TransactionService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.io.ByteArrayOutputStream;
import java.io.PrintWriter;
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/transactions")
public class TransactionController {

    @Autowired
    private TransactionService transactionService;

    @GetMapping
    @PreAuthorize("hasAuthority('VIEW_LEDGER')")
    public ResponseEntity<List<TransactionDto>> getAll(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate dateFrom,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate dateTo,
            @RequestParam(required = false) String type,
            @RequestParam(required = false) Long accountId,
            @RequestParam(required = false) String contact,
            @RequestParam(required = false) String company,
            @RequestParam(required = false) String category,
            @RequestParam(required = false) String staff,
            @RequestParam(required = false) String paymentMethod) {
        return ResponseEntity.ok(transactionService.getTransactions(
                dateFrom, dateTo, type, accountId, contact, company, category, staff, paymentMethod));
    }

    @GetMapping("/lookups")
    @PreAuthorize("hasAuthority('VIEW_LEDGER')")
    public ResponseEntity<Map<String, List<String>>> getLookups() {
        return ResponseEntity.ok(transactionService.getFilterOptions());
    }

    @GetMapping("/export.csv")
    @PreAuthorize("hasAuthority('VIEW_LEDGER')")
    public ResponseEntity<byte[]> exportCsv(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate dateFrom,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate dateTo,
            @RequestParam(required = false) String type,
            @RequestParam(required = false) Long accountId,
            @RequestParam(required = false) String contact,
            @RequestParam(required = false) String company,
            @RequestParam(required = false) String category,
            @RequestParam(required = false) String staff,
            @RequestParam(required = false) String paymentMethod) throws Exception {

        List<TransactionDto> rows = transactionService.getTransactions(
                dateFrom, dateTo, type, accountId, contact, company, category, staff, paymentMethod);

        ByteArrayOutputStream out = new ByteArrayOutputStream();
        try (PrintWriter w = new PrintWriter(out, true, StandardCharsets.UTF_8)) {
            w.println("Transaction ID,Date,Account,Company,Contact,Category,Type,Description,Debit,Credit,Currency");
            for (TransactionDto t : rows) {
                w.println(String.join(",",
                        csv(t.getTransactionId()), csv(String.valueOf(t.getDate())), csv(t.getAccountTitle()),
                        csv(t.getCompany()), csv(t.getContact()), csv(t.getCategory()), csv(t.getType()),
                        csv(t.getDescription()), csv(String.valueOf(t.getDebit())), csv(String.valueOf(t.getCredit())),
                        csv(t.getCurrency())));
            }
        }

        return ResponseEntity.ok()
                .header("Content-Disposition", "attachment; filename=transactions_export.csv")
                .contentType(MediaType.parseMediaType("text/csv"))
                .body(out.toByteArray());
    }

    private String csv(String s) {
        if (s == null) return "";
        String escaped = s.replace("\"", "\"\"");
        return "\"" + escaped + "\"";
    }
}