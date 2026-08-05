package com.bizmotion.rbca.controller;

import com.bizmotion.rbca.dto.CreateDepositRequest;
import com.bizmotion.rbca.dto.DepositDto;
import com.bizmotion.rbca.dto.DepositLookupsDto;
import com.bizmotion.rbca.service.DepositService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/deposits")
public class DepositController {

    @Autowired
    private DepositService depositService;

    @GetMapping
    @PreAuthorize("hasAuthority('VIEW_DEPOSIT')")
    public ResponseEntity<List<DepositDto>> getAll() {
        return ResponseEntity.ok(depositService.getAll());
    }

    @GetMapping("/lookups")
    @PreAuthorize("hasAuthority('VIEW_DEPOSIT')")
    public ResponseEntity<DepositLookupsDto> getLookups() {
        return ResponseEntity.ok(depositService.getLookups());
    }

    @PostMapping
    @PreAuthorize("hasAuthority('CREATE_DEPOSIT')")
    public ResponseEntity<DepositDto> create(@RequestBody @Valid CreateDepositRequest req) {
        return ResponseEntity.status(201).body(depositService.create(req, null));
    }
}
