package com.bizmotion.rbca.service;

import com.bizmotion.rbca.dto.CreateDepositRequest;
import com.bizmotion.rbca.dto.DepositDto;
import com.bizmotion.rbca.dto.DepositLookupsDto;
import com.bizmotion.rbca.entity.Account;
import com.bizmotion.rbca.entity.Deposit;
import com.bizmotion.rbca.repository.AccountRepository;
import com.bizmotion.rbca.repository.DepositRepository;
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
public class DepositService {

    @Autowired private DepositRepository repo;
    @Autowired private AccountRepository accountRepo;

    public List<DepositDto> getAll() {
        return repo.findAll().stream()
                .sorted((a, b) -> b.getId().compareTo(a.getId()))
                .map(this::toDto).collect(Collectors.toList());
    }

    public DepositLookupsDto getLookups() {
        return new DepositLookupsDto(
                repo.findDistinctCategories(),
                repo.findDistinctCompanies(),
                repo.findDistinctPayers(),
                repo.findDistinctStaff(),
                repo.findDistinctPaymentMethods()
        );
    }

    @Transactional
    public DepositDto create(CreateDepositRequest req, Long callerId) {
        if (req.getAmount() == null || req.getAmount().compareTo(BigDecimal.ZERO) <= 0) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Amount must be greater than zero");
        }
        Account account = accountRepo.findById(req.getAccountId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Account not found"));

        Deposit dep = new Deposit();
        dep.setDepositCode(generateCode());
        dep.setAccount(account);
        dep.setDate(req.getDate());
        dep.setDescription(req.getDescription());
        dep.setCurrency(req.getCurrency() != null && !req.getCurrency().isBlank() ? req.getCurrency() : "BDT");
        dep.setAmount(req.getAmount());
        dep.setCategory(blankToNull(req.getCategory()));
        dep.setTags(blankToNull(req.getTags()));
        dep.setCompany(blankToNull(req.getCompany()));
        dep.setPayer(blankToNull(req.getPayer()));
        dep.setStaff(blankToNull(req.getStaff()));
        dep.setPaymentMethod(blankToNull(req.getPaymentMethod()));
        dep.setReferenceNo(req.getReferenceNo());
        dep.setCreatedBy(callerId);

        return toDto(repo.save(dep));
    }

    private String blankToNull(String s) { return (s == null || s.isBlank()) ? null : s.trim(); }

    private String generateCode() {
        int year = Year.now().getValue();
        String prefix = "DEP-" + year + "-";
        long count = repo.count() + 1;
        String candidate;
        do {
            candidate = String.format("%s%04d", prefix, count);
            count++;
        } while (repo.existsByDepositCode(candidate));
        return candidate;
    }

    private DepositDto toDto(Deposit d) {
        return new DepositDto(
                d.getId(), d.getDepositCode(), d.getAccount().getId(), d.getAccount().getAccountTitle(),
                d.getDate(), d.getDescription(), d.getCurrency(), d.getAmount(),
                d.getCategory(), d.getTags(), d.getCompany(), d.getPayer(), d.getStaff(), d.getPaymentMethod(),
                d.getReferenceNo(), d.getCreatedBy(), d.getCreatedAt()
        );
    }
}
