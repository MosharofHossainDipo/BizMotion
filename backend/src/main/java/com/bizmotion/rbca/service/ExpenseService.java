package com.bizmotion.rbca.service;

import com.bizmotion.rbca.dto.CreateExpenseRequest;
import com.bizmotion.rbca.dto.ExpenseDto;
import com.bizmotion.rbca.dto.ExpenseLookupsDto;
import com.bizmotion.rbca.entity.Account;
import com.bizmotion.rbca.entity.Expense;
import com.bizmotion.rbca.repository.AccountRepository;
import com.bizmotion.rbca.repository.ExpenseRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.math.BigDecimal;
import java.time.Year;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class ExpenseService {

    @Autowired private ExpenseRepository repo;
    @Autowired private AccountRepository accountRepo;

    private static final List<String> ALLOWED_STATUSES = List.of("Cleared", "Pending");

    public List<ExpenseDto> getAll() {
        return repo.findAll().stream()
                .sorted((a, b) -> b.getId().compareTo(a.getId()))
                .map(this::toDto).collect(Collectors.toList());
    }

    public ExpenseLookupsDto getLookups() {
        return new ExpenseLookupsDto(
                repo.findDistinctCategories(),
                repo.findDistinctStaff(),
                repo.findDistinctPaymentMethods()
        );
    }

    @Transactional
    public ExpenseDto create(CreateExpenseRequest req, Long callerId) {
        if (req.getAmount() == null || req.getAmount().compareTo(BigDecimal.ZERO) <= 0) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Amount must be greater than zero");
        }
        Account account = accountRepo.findById(req.getAccountId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Account not found"));

        String status = req.getStatus();
        if (status == null || !ALLOWED_STATUSES.contains(status)) status = "Cleared";

        Expense exp = new Expense();
        exp.setExpenseCode(generateCode());
        exp.setAccount(account);
        exp.setDate(req.getDate());
        exp.setDescription(req.getDescription());
        exp.setCurrency(req.getCurrency() != null && !req.getCurrency().isBlank() ? req.getCurrency() : "BDT");
        exp.setAmount(req.getAmount());
        exp.setCategory(blankToNull(req.getCategory()));
        exp.setTags(blankToNull(req.getTags()));
        exp.setCompany(blankToNull(req.getCompany()));
        exp.setPayee(blankToNull(req.getPayee()));
        exp.setStaff(blankToNull(req.getStaff()));
        exp.setPaymentMethod(blankToNull(req.getPaymentMethod()));
        exp.setStatus(status);
        exp.setReferenceNo(req.getReferenceNo());
        exp.setCreatedBy(callerId);

        return toDto(repo.save(exp));
    }

    private String blankToNull(String s) { return (s == null || s.isBlank()) ? null : s.trim(); }

    private String generateCode() {
        int year = Year.now().getValue();
        String prefix = "EXP-" + year + "-";
        long count = repo.count() + 1;
        String candidate;
        do {
            candidate = String.format("%s%04d", prefix, count);
            count++;
        } while (repo.existsByExpenseCode(candidate));
        return candidate;
    }

    private ExpenseDto toDto(Expense e) {
        return new ExpenseDto(
                e.getId(), e.getExpenseCode(), e.getAccount().getId(), e.getAccount().getAccountTitle(),
                e.getDate(), e.getDescription(), e.getCurrency(), e.getAmount(),
                e.getCategory(), e.getTags(), e.getCompany(), e.getPayee(), e.getStaff(), e.getPaymentMethod(),
                e.getStatus(), e.getReferenceNo(), e.getCreatedBy(), e.getCreatedAt()
        );
    }
}
