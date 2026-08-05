package com.bizmotion.rbca.controller;

import com.bizmotion.rbca.dto.CreateTransferRequest;
import com.bizmotion.rbca.dto.TransferDto;
import com.bizmotion.rbca.service.TransferService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/transfers")
public class TransferController {

    @Autowired
    private TransferService transferService;

    @GetMapping
    @PreAuthorize("hasAuthority('VIEW_TRANSFER')")
    public ResponseEntity<List<TransferDto>> getAll() {
        return ResponseEntity.ok(transferService.getAll());
    }

    @GetMapping("/payment-methods")
    @PreAuthorize("hasAuthority('VIEW_TRANSFER')")
    public ResponseEntity<List<String>> getPaymentMethods() {
        return ResponseEntity.ok(transferService.getPaymentMethods());
    }

    @PostMapping
    @PreAuthorize("hasAuthority('CREATE_TRANSFER')")
    public ResponseEntity<TransferDto> create(@RequestBody @Valid CreateTransferRequest req) {
        return ResponseEntity.status(201).body(transferService.create(req, null));
    }
}
