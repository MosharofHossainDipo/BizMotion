package com.bizmotion.rbca.controller;

import com.bizmotion.rbca.dto.CreateExpenseRequest;
import com.bizmotion.rbca.dto.ExpenseDto;
import com.bizmotion.rbca.dto.ExpenseLookupsDto;
import com.bizmotion.rbca.service.ExpenseService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/expenses")
public class ExpenseController {

    @Autowired
    private ExpenseService expenseService;

    @GetMapping
    @PreAuthorize("hasAuthority('VIEW_EXPENSE')")
    public ResponseEntity<List<ExpenseDto>> getAll() {
        return ResponseEntity.ok(expenseService.getAll());
    }

    @GetMapping("/lookups")
    @PreAuthorize("hasAuthority('VIEW_EXPENSE')")
    public ResponseEntity<ExpenseLookupsDto> getLookups() {
        return ResponseEntity.ok(expenseService.getLookups());
    }

    @PostMapping
    @PreAuthorize("hasAuthority('CREATE_EXPENSE')")
    public ResponseEntity<ExpenseDto> create(@RequestBody @Valid CreateExpenseRequest req) {
        return ResponseEntity.status(201).body(expenseService.create(req, null));
    }
}
