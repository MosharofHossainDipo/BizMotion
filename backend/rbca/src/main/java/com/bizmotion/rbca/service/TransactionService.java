package com.bizmotion.rbca.service;

import com.bizmotion.rbca.dto.TransactionDto;
import com.bizmotion.rbca.entity.Account;
import com.bizmotion.rbca.entity.Deposit;
import com.bizmotion.rbca.entity.Expense;
import com.bizmotion.rbca.entity.Transfer;
import com.bizmotion.rbca.repository.AccountRepository;
import com.bizmotion.rbca.repository.DepositRepository;
import com.bizmotion.rbca.repository.ExpenseRepository;
import com.bizmotion.rbca.repository.TransferRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class TransactionService {

    @Autowired private AccountRepository  accountRepo;
    @Autowired private DepositRepository  depositRepo;
    @Autowired private ExpenseRepository  expenseRepo;
    @Autowired private TransferRepository transferRepo;

    /** Builds the full unified ledger, newest first, then applies whichever
     *  filters were supplied. All filtering happens in memory over the
     *  assembled list — simplest correct approach given the ledger is a
     *  union across four different sources with no shared table/view. */
    public List<TransactionDto> getTransactions(
            LocalDate dateFrom, LocalDate dateTo, String type, Long accountId,
            String contact, String company, String category, String staff, String paymentMethod) {

        List<TransactionDto> all = buildAll();

        return all.stream()
                .filter(t -> dateFrom == null || !t.getDate().isBefore(dateFrom))
                .filter(t -> dateTo == null || !t.getDate().isAfter(dateTo))
                .filter(t -> type == null || type.isBlank() || type.equalsIgnoreCase("all") || t.getType().equalsIgnoreCase(type))
                .filter(t -> accountId == null || accountId.equals(t.getAccountId()))
                .filter(t -> contact == null || contact.isBlank() || contact.equalsIgnoreCase("all") || contact.equalsIgnoreCase(t.getContact()))
                .filter(t -> company == null || company.isBlank() || company.equalsIgnoreCase("all") || company.equalsIgnoreCase(t.getCompany()))
                .filter(t -> category == null || category.isBlank() || category.equalsIgnoreCase("all") || category.equalsIgnoreCase(t.getCategory()))
                .filter(t -> staff == null || staff.isBlank() || staff.equalsIgnoreCase("all") || staff.equalsIgnoreCase(t.getStaff()))
                .filter(t -> paymentMethod == null || paymentMethod.isBlank() || paymentMethod.equalsIgnoreCase("all") || paymentMethod.equalsIgnoreCase(t.getPaymentMethod()))
                .sorted(Comparator.comparing(TransactionDto::getDate).reversed())
                .collect(Collectors.toList());
    }

    public Map<String, List<String>> getFilterOptions() {
        List<TransactionDto> all = buildAll();
        Map<String, List<String>> options = new LinkedHashMap<>();
        options.put("types", distinctSorted(all, TransactionDto::getType));
        options.put("contacts", distinctSorted(all, TransactionDto::getContact));
        options.put("companies", distinctSorted(all, TransactionDto::getCompany));
        options.put("categories", distinctSorted(all, TransactionDto::getCategory));
        options.put("staff", distinctSorted(all, TransactionDto::getStaff));
        options.put("paymentMethods", distinctSorted(all, TransactionDto::getPaymentMethod));
        return options;
    }

    private List<String> distinctSorted(List<TransactionDto> all, java.util.function.Function<TransactionDto, String> getter) {
        return all.stream().map(getter).filter(Objects::nonNull).filter(s -> !s.isBlank())
                .distinct().sorted().collect(Collectors.toList());
    }

    private List<TransactionDto> buildAll() {
        List<TransactionDto> list = new ArrayList<>();

        for (Account acc : accountRepo.findAll()) {
            if (acc.getInitialBalanceBdt() != null && acc.getInitialBalanceBdt().compareTo(BigDecimal.ZERO) != 0) {
                list.add(new TransactionDto(
                        "OPEN-" + acc.getAccountCode(), acc.getCreatedAt().atZone(java.time.ZoneId.systemDefault()).toLocalDate(),
                        acc.getId(), acc.getAccountTitle(), null, null, null, "Opening Balance",
                        "Opening balance for " + acc.getAccountTitle(),
                        BigDecimal.ZERO, acc.getInitialBalanceBdt(), null, null, "BDT"
                ));
            }
        }

        for (Deposit d : depositRepo.findAll()) {
            list.add(new TransactionDto(
                    d.getDepositCode(), d.getDate(), d.getAccount().getId(), d.getAccount().getAccountTitle(),
                    d.getCompany(), d.getPayer(), d.getCategory(), "Deposit", d.getDescription(),
                    BigDecimal.ZERO, d.getAmount(), d.getPaymentMethod(), d.getStaff(), d.getCurrency()
            ));
        }

        for (Expense e : expenseRepo.findAll()) {
            list.add(new TransactionDto(
                    e.getExpenseCode(), e.getDate(), e.getAccount().getId(), e.getAccount().getAccountTitle(),
                    e.getCompany(), e.getPayee(), e.getCategory(), "Expense", e.getDescription(),
                    e.getAmount(), BigDecimal.ZERO, e.getPaymentMethod(), e.getStaff(), e.getCurrency()
            ));
        }

        for (Transfer t : transferRepo.findAll()) {
            list.add(new TransactionDto(
                    t.getTransferCode() + "-OUT", t.getDate(), t.getFromAccount().getId(), t.getFromAccount().getAccountTitle(),
                    null, null, null, "Transfer Out",
                    "Transfer to " + t.getToAccount().getAccountTitle() + (t.getDescription() != null ? " — " + t.getDescription() : ""),
                    t.getAmount(), BigDecimal.ZERO, t.getPaymentMethod(), null, t.getCurrency()
            ));
            list.add(new TransactionDto(
                    t.getTransferCode() + "-IN", t.getDate(), t.getToAccount().getId(), t.getToAccount().getAccountTitle(),
                    null, null, null, "Transfer In",
                    "Transfer from " + t.getFromAccount().getAccountTitle() + (t.getDescription() != null ? " — " + t.getDescription() : ""),
                    BigDecimal.ZERO, t.getAmount(), t.getPaymentMethod(), null, t.getCurrency()
            ));
        }

        return list;
    }
}
