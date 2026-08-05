package com.bizmotion.rbca.service;

import com.bizmotion.rbca.dto.AccountDto;
import com.bizmotion.rbca.dto.CreateAccountRequest;
import com.bizmotion.rbca.dto.UpdateAccountRequest;
import com.bizmotion.rbca.entity.Account;
import com.bizmotion.rbca.repository.AccountRepository;
import org.springframework.beans.factory.annotation.Autowired;
import com.bizmotion.rbca.repository.DepositRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;
import com.bizmotion.rbca.repository.ExpenseRepository;
import com.bizmotion.rbca.repository.TransferRepository;

import java.math.BigDecimal;
import java.time.Year;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class AccountService {

    @Autowired private AccountRepository repo;
    @Autowired private DepositRepository  depositRepo;
    @Autowired private ExpenseRepository  expenseRepo;
    @Autowired private TransferRepository transferRepo;

    public List<AccountDto> getAll() {
        return repo.findAll().stream()
                .sorted((a, b) -> a.getId().compareTo(b.getId()))
                .map(this::toDto).collect(Collectors.toList());
    }

    public AccountDto getById(Long id) {
        return toDto(repo.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Account not found")));
    }

    @Transactional
    public AccountDto create(CreateAccountRequest req, Long callerId) {
        if (repo.existsByAccountTitleIgnoreCase(req.getAccountTitle()))
            throw new ResponseStatusException(HttpStatus.CONFLICT, "An account with this title already exists");

        Account acc = new Account();
        acc.setAccountCode(generateCode());
        acc.setAccountTitle(req.getAccountTitle());
        acc.setDescription(req.getDescription());
        acc.setAccountNumber(req.getAccountNumber());
        acc.setContactPerson(req.getContactPerson());
        acc.setPhone(req.getPhone());
        acc.setInternetBankingUrl(req.getInternetBankingUrl());
        acc.setInitialBalanceBdt(nz(req.getInitialBalanceBdt()));
        acc.setInitialBalanceUsd(nz(req.getInitialBalanceUsd()));
        acc.setOwnerId(callerId);
        acc.setStatus("Active");
        acc.setCreatedBy(callerId);

        return toDto(repo.save(acc));
    }

    @Transactional
    public AccountDto update(Long id, UpdateAccountRequest req) {
        Account acc = repo.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Account not found"));

        if (req.getAccountTitle()       != null) acc.setAccountTitle(req.getAccountTitle());
        if (req.getDescription()        != null) acc.setDescription(req.getDescription());
        if (req.getAccountNumber()      != null) acc.setAccountNumber(req.getAccountNumber());
        if (req.getContactPerson()      != null) acc.setContactPerson(req.getContactPerson());
        if (req.getPhone()              != null) acc.setPhone(req.getPhone());
        if (req.getInternetBankingUrl() != null) acc.setInternetBankingUrl(req.getInternetBankingUrl());
        if (req.getInitialBalanceBdt()  != null) acc.setInitialBalanceBdt(req.getInitialBalanceBdt());
        if (req.getInitialBalanceUsd()  != null) acc.setInitialBalanceUsd(req.getInitialBalanceUsd());

        return toDto(repo.save(acc));
    }

    /** Adjusts the account's opening balance — separate from a general
     *  update so it can later be audit-logged as its own distinct action,
     *  per the spec's "Record Initial Balance" feature. */
    @Transactional
    public AccountDto recordInitialBalance(Long id, BigDecimal bdt, BigDecimal usd) {
        Account acc = repo.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Account not found"));
        if (bdt != null) acc.setInitialBalanceBdt(bdt);
        if (usd != null) acc.setInitialBalanceUsd(usd);
        return toDto(repo.save(acc));
    }

    @Transactional
    public void setStatus(Long id, boolean active) {
        Account acc = repo.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Account not found"));
        acc.setStatus(active ? "Active" : "Inactive");
        repo.save(acc);
    }

    /** Soft delete per spec — status flip rather than a real row removal,
     *  so historical deposits/expenses/transfers keep a valid reference. */
    @Transactional
    public void delete(Long id) {
        Account acc = repo.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Account not found"));
        acc.setStatus("Deleted");
        repo.save(acc);
    }

    private String generateCode() {
        int year = Year.now().getValue();
        String prefix = "ACC-" + year + "-";
        long nextSeq = repo.findCodesWithPrefix(prefix).stream()
                .map(c -> c.substring(prefix.length()))
                .filter(s -> s.matches("\\d+"))
                .mapToLong(Long::parseLong)
                .max()
                .orElse(0L) + 1;
        return String.format("%s%04d", prefix, nextSeq);
    }

    private BigDecimal nz(BigDecimal v) { return v != null ? v : BigDecimal.ZERO; }

    /** Totals from Deposits, Expenses and Transfers are pulled from their
     *  respective repositories and combined with the account's opening
     *  balance to compute the live Current Balance. */
    private AccountDto toDto(Account acc) {
        BigDecimal totalDeposits     = depositRepo.sumAmountByAccountId(acc.getId());
        BigDecimal totalExpenses     = expenseRepo.sumAmountByAccountId(acc.getId());
        BigDecimal totalTransfersIn  = transferRepo.sumInByAccountId(acc.getId());
        BigDecimal totalTransfersOut = transferRepo.sumOutByAccountId(acc.getId());

        BigDecimal currentBalance = acc.getInitialBalanceBdt()
                .add(totalDeposits)
                .add(totalTransfersIn)
                .subtract(totalExpenses)
                .subtract(totalTransfersOut);

        return new AccountDto(
                acc.getId(), acc.getAccountCode(), acc.getAccountTitle(), acc.getDescription(),
                acc.getAccountNumber(), acc.getContactPerson(), acc.getPhone(), acc.getInternetBankingUrl(),
                acc.getInitialBalanceBdt(), acc.getInitialBalanceUsd(),
                totalDeposits, totalExpenses, totalTransfersIn, totalTransfersOut, currentBalance,
                acc.getStatus(), acc.getCreatedBy(), acc.getCreatedAt(), acc.getUpdatedAt()
        );
    }
}