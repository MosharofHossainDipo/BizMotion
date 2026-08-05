package com.bizmotion.rbca.controller;

import com.bizmotion.rbca.dto.CreatePaymentRequest;
import com.bizmotion.rbca.dto.PaymentDto;
import com.bizmotion.rbca.service.PaymentService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/invoices/{invoiceId}/payments")
public class PaymentController {

    @Autowired
    private PaymentService paymentService;

    @GetMapping
    @PreAuthorize("hasAuthority('VIEW_PAYMENT')")
    public ResponseEntity<List<PaymentDto>> getForInvoice(@PathVariable Long invoiceId) {
        return ResponseEntity.ok(paymentService.getForInvoice(invoiceId));
    }

    @PostMapping
    @PreAuthorize("hasAuthority('CREATE_PAYMENT')")
    public ResponseEntity<PaymentDto> create(@PathVariable Long invoiceId, @RequestBody @Valid CreatePaymentRequest req) {
        return ResponseEntity.status(201).body(paymentService.create(invoiceId, req, null));
    }
}
