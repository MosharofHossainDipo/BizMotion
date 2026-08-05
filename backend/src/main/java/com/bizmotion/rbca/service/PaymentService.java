package com.bizmotion.rbca.service;

import com.bizmotion.rbca.dto.CreateDepositRequest;
import com.bizmotion.rbca.dto.CreatePaymentRequest;
import com.bizmotion.rbca.dto.DepositDto;
import com.bizmotion.rbca.dto.PaymentDto;
import com.bizmotion.rbca.entity.Account;
import com.bizmotion.rbca.entity.Invoice;
import com.bizmotion.rbca.entity.Payment;
import com.bizmotion.rbca.repository.AccountRepository;
import com.bizmotion.rbca.repository.InvoiceRepository;
import com.bizmotion.rbca.repository.PaymentRepository;
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
public class PaymentService {

    @Autowired private PaymentRepository repo;
    @Autowired private InvoiceRepository invoiceRepo;
    @Autowired private AccountRepository accountRepo;
    @Autowired private DepositService depositService;
    @Autowired private InvoiceService invoiceService;

    public List<PaymentDto> getForInvoice(Long invoiceId) {
        return repo.findByInvoiceId(invoiceId).stream().map(this::toDto).collect(Collectors.toList());
    }

    @Transactional
    public PaymentDto create(Long invoiceId, CreatePaymentRequest req, Long callerId) {
        Invoice invoice = invoiceRepo.findById(invoiceId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Invoice not found"));
        Account account = accountRepo.findById(req.getAccountId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Account not found"));

        if (req.getAmount() == null || req.getAmount().compareTo(BigDecimal.ZERO) <= 0) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Payment amount cannot be zero");
        }

        BigDecimal alreadyPaid = repo.sumByInvoiceId(invoiceId);
        BigDecimal remaining = invoice.getGrandTotal().subtract(alreadyPaid);

        if (req.getAmount().compareTo(remaining) > 0) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Payment amount (" + req.getAmount() + ") exceeds remaining balance (" + remaining + ")");
        }

        String defaultDescription = "Invoice Payment - " + invoice.getInvoiceNumber();

        Payment payment = new Payment();
        payment.setPaymentCode(generateCode());
        payment.setInvoice(invoice);
        payment.setCustomer(invoice.getCustomer());
        payment.setAccount(account);
        payment.setDate(req.getDate());
        payment.setAmount(req.getAmount());
        payment.setCurrency(req.getCurrency() != null && !req.getCurrency().isBlank() ? req.getCurrency() : "BDT");
        payment.setCategory(blankToNull(req.getCategory()));
        payment.setPayer(req.getPayer() != null && !req.getPayer().isBlank() ? req.getPayer() : invoice.getCustomer().getName());
        payment.setPaymentMethod(blankToNull(req.getPaymentMethod()));
        payment.setReferenceNo(req.getReferenceNo());
        payment.setDescription(req.getDescription() != null && !req.getDescription().isBlank() ? req.getDescription() : defaultDescription);
        payment.setNotes(req.getNotes());
        payment.setCreatedBy(callerId);

        // Every successful payment automatically creates a matching Deposit —
        // same account, amount, and reference, so Accounting stays in sync.
        CreateDepositRequest depositReq = new CreateDepositRequest();
        depositReq.setAccountId(req.getAccountId());
        depositReq.setDate(req.getDate());
        depositReq.setDescription(payment.getDescription());
        depositReq.setCurrency(payment.getCurrency());
        depositReq.setAmount(req.getAmount());
        depositReq.setCategory(payment.getCategory() != null ? payment.getCategory() : "Invoice Payment");
        depositReq.setPayer(payment.getPayer());
        depositReq.setPaymentMethod(payment.getPaymentMethod());
        depositReq.setReferenceNo(req.getReferenceNo());
        DepositDto deposit = depositService.create(depositReq, callerId);
        payment.setDepositId(deposit.getId());

        Payment saved = repo.save(payment);

        BigDecimal newTotalPaid = alreadyPaid.add(req.getAmount());
        BigDecimal newRemaining = invoice.getGrandTotal().subtract(newTotalPaid);
        String newStatus;
        if (newRemaining.compareTo(BigDecimal.ZERO) <= 0) newStatus = "Paid";
        else if (newTotalPaid.compareTo(BigDecimal.ZERO) > 0) newStatus = "Partially Paid";
        else newStatus = "Unpaid";
        invoiceService.setStatus(invoiceId, newStatus);

        return toDto(saved);
    }

    private String blankToNull(String s) { return (s == null || s.isBlank()) ? null : s.trim(); }

    private String generateCode() {
        int year = Year.now().getValue();
        String prefix = "PAY-" + year + "-";
        long count = repo.count() + 1;
        String candidate;
        do {
            candidate = String.format("%s%04d", prefix, count);
            count++;
        } while (repo.existsByPaymentCode(candidate));
        return candidate;
    }

    private PaymentDto toDto(Payment p) {
        return new PaymentDto(
                p.getId(), p.getPaymentCode(), p.getInvoice().getId(), p.getInvoice().getInvoiceNumber(),
                p.getCustomer().getId(), p.getCustomer().getName(), p.getAccount().getId(), p.getAccount().getAccountTitle(),
                p.getDate(), p.getAmount(), p.getCurrency(), p.getCategory(), p.getPayer(), p.getPaymentMethod(),
                p.getReferenceNo(), p.getDescription(), p.getNotes(), p.getCreatedBy(), p.getCreatedAt()
        );
    }
}
