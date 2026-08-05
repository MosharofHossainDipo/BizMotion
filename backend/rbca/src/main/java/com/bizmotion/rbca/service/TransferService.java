package com.bizmotion.rbca.service;

import com.bizmotion.rbca.dto.CreateTransferRequest;
import com.bizmotion.rbca.dto.TransferDto;
import com.bizmotion.rbca.entity.Account;
import com.bizmotion.rbca.entity.Transfer;
import com.bizmotion.rbca.repository.AccountRepository;
import com.bizmotion.rbca.repository.DepositRepository;
import com.bizmotion.rbca.repository.ExpenseRepository;
import com.bizmotion.rbca.repository.TransferRepository;
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
public class TransferService {

    @Autowired private TransferRepository repo;
    @Autowired private AccountRepository  accountRepo;
    @Autowired private DepositRepository  depositRepo;
    @Autowired private ExpenseRepository  expenseRepo;

    public List<TransferDto> getAll() {
        return repo.findAll().stream()
                .sorted((a, b) -> b.getId().compareTo(a.getId()))
                .map(this::toDto).collect(Collectors.toList());
    }

    public List<String> getPaymentMethods() {
        return repo.findDistinctPaymentMethods();
    }

    @Transactional
    public TransferDto create(CreateTransferRequest req, Long callerId) {
        if (req.getAmount() == null || req.getAmount().compareTo(BigDecimal.ZERO) <= 0) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Amount must be greater than zero");
        }
        if (req.getFromAccountId().equals(req.getToAccountId())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Source and destination account must be different");
        }

        Account from = accountRepo.findById(req.getFromAccountId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Source account not found"));
        Account to = accountRepo.findById(req.getToAccountId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Destination account not found"));

        BigDecimal currentBalance = currentBalanceOf(from);
        if (currentBalance.compareTo(req.getAmount()) < 0) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Insufficient balance in " + from.getAccountTitle() + " (available: " + currentBalance + ")");
        }

        Transfer t = new Transfer();
        t.setTransferCode(generateCode());
        t.setFromAccount(from);
        t.setToAccount(to);
        t.setDate(req.getDate());
        t.setDescription(req.getDescription());
        t.setCurrency(req.getCurrency() != null && !req.getCurrency().isBlank() ? req.getCurrency() : "BDT");
        t.setAmount(req.getAmount());
        t.setTags(blankToNull(req.getTags()));
        t.setPaymentMethod(blankToNull(req.getPaymentMethod()));
        t.setReferenceNo(req.getReferenceNo());
        t.setCreatedBy(callerId);

        return toDto(repo.save(t));
    }

    /** Mirrors AccountService's balance formula (opening + deposits + transfers-in
     *  − expenses − transfers-out) so the insufficient-balance check matches
     *  exactly what the user sees on Manage Accounts. */
    private BigDecimal currentBalanceOf(Account acc) {
        BigDecimal deposits     = depositRepo.sumAmountByAccountId(acc.getId());
        BigDecimal expenses     = expenseRepo.sumAmountByAccountId(acc.getId());
        BigDecimal transfersIn  = repo.sumInByAccountId(acc.getId());
        BigDecimal transfersOut = repo.sumOutByAccountId(acc.getId());
        return acc.getInitialBalanceBdt().add(deposits).add(transfersIn).subtract(expenses).subtract(transfersOut);
    }

    private String blankToNull(String s) { return (s == null || s.isBlank()) ? null : s.trim(); }

    private String generateCode() {
        int year = Year.now().getValue();
        String prefix = "TRF-" + year + "-";
        long count = repo.count() + 1;
        String candidate;
        do {
            candidate = String.format("%s%04d", prefix, count);
            count++;
        } while (repo.existsByTransferCode(candidate));
        return candidate;
    }

    private TransferDto toDto(Transfer t) {
        return new TransferDto(
                t.getId(), t.getTransferCode(),
                t.getFromAccount().getId(), t.getFromAccount().getAccountTitle(),
                t.getToAccount().getId(), t.getToAccount().getAccountTitle(),
                t.getDate(), t.getDescription(), t.getCurrency(), t.getAmount(),
                t.getTags(), t.getPaymentMethod(), t.getReferenceNo(), t.getCreatedBy(), t.getCreatedAt()
        );
    }
}
