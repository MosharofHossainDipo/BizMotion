package com.bizmotion.rbca.controller;

import com.bizmotion.rbca.dto.AccountDto;
import com.bizmotion.rbca.dto.CreateAccountRequest;
import com.bizmotion.rbca.dto.UpdateAccountRequest;
import com.bizmotion.rbca.service.AccountService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/accounts")
public class AccountController {

    @Autowired
    private AccountService accountService;

    @GetMapping
    @PreAuthorize("hasAuthority('VIEW_ACCOUNT')")
    public ResponseEntity<List<AccountDto>> getAll() {
        return ResponseEntity.ok(accountService.getAll());
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasAuthority('VIEW_ACCOUNT')")
    public ResponseEntity<AccountDto> getById(@PathVariable Long id) {
        return ResponseEntity.ok(accountService.getById(id));
    }

    @PostMapping
    @PreAuthorize("hasAuthority('CREATE_ACCOUNT')")
    public ResponseEntity<AccountDto> create(@RequestBody @Valid CreateAccountRequest req) {
        return ResponseEntity.status(201).body(accountService.create(req, null));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAuthority('EDIT_ACCOUNT')")
    public ResponseEntity<AccountDto> update(@PathVariable Long id, @RequestBody UpdateAccountRequest req) {
        return ResponseEntity.ok(accountService.update(id, req));
    }

    @PutMapping("/{id}/initial-balance")
    @PreAuthorize("hasAuthority('EDIT_ACCOUNT')")
    public ResponseEntity<AccountDto> recordInitialBalance(@PathVariable Long id, @RequestBody Map<String, BigDecimal> body) {
        return ResponseEntity.ok(accountService.recordInitialBalance(id, body.get("initialBalanceBdt"), body.get("initialBalanceUsd")));
    }

    @PutMapping("/{id}/status")
    @PreAuthorize("hasAuthority('EDIT_ACCOUNT')")
    public ResponseEntity<String> setStatus(@PathVariable Long id, @RequestBody Map<String, Boolean> body) {
        accountService.setStatus(id, Boolean.TRUE.equals(body.get("active")));
        return ResponseEntity.ok("Status updated");
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasAuthority('DELETE_ACCOUNT')")
    public ResponseEntity<String> delete(@PathVariable Long id) {
        accountService.delete(id);
        return ResponseEntity.ok("Account deleted");
    }
}
