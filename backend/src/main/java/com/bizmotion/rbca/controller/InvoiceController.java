package com.bizmotion.rbca.controller;

import com.bizmotion.rbca.dto.CreateInvoiceRequest;
import com.bizmotion.rbca.dto.InvoiceDto;
import com.bizmotion.rbca.dto.InvoiceImportResult;
import com.bizmotion.rbca.dto.Pdfgenerationrequest;
import com.bizmotion.rbca.dto.UpdateInvoiceRequest;
import com.bizmotion.rbca.service.Invoicepdfservice;
import com.bizmotion.rbca.service.InvoiceService;

import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ContentDisposition;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/invoices")
public class InvoiceController {

    @Autowired
    private InvoiceService invoiceService;

    @Autowired
    private Invoicepdfservice invoicepdfservice;

    @GetMapping
    @PreAuthorize("hasAuthority('VIEW_INVOICE')")
    public ResponseEntity<List<InvoiceDto>> getAll() {
        return ResponseEntity.ok(invoiceService.getAll());
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasAuthority('VIEW_INVOICE')")
    public ResponseEntity<InvoiceDto> getById(@PathVariable Long id) {
        return ResponseEntity.ok(invoiceService.getById(id));
    }

    @PostMapping
    @PreAuthorize("hasAuthority('CREATE_INVOICE')")
    public ResponseEntity<InvoiceDto> create(
            @RequestBody @Valid CreateInvoiceRequest req,
            @RequestParam(defaultValue = "false") boolean finalize) {
        return ResponseEntity.status(201).body(invoiceService.create(req, finalize, null));
    }

    @PostMapping("/{id}/clone")
    @PreAuthorize("hasAuthority('CREATE_INVOICE')")
    public ResponseEntity<InvoiceDto> clone(@PathVariable Long id) {
        return ResponseEntity.status(201).body(invoiceService.clone(id, null));
    }

    /** Generates a real PDF (iText) — page breaks, repeating header/footer,
     *  and the never-split totals/signature blocks are all handled
     *  server-side, precisely and identically every time. */
    @PostMapping("/{id}/pdf")
    @PreAuthorize("hasAuthority('VIEW_INVOICE')")
    public ResponseEntity<byte[]> generatePdf(
            @PathVariable Long id,
            @RequestBody(required = false) Pdfgenerationrequest req) {
        InvoiceDto inv = invoiceService.getById(id);
        boolean letterhead = req != null && req.isLetterhead();
        String signature = req != null ? req.getSignatureImageBase64() : null;

        byte[] pdfBytes;
        try {
            pdfBytes = invoicepdfservice.generate(inv, letterhead, signature);
        } catch (IOException e) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "Failed to generate PDF");
        }

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_PDF);
        headers.setContentDisposition(
                ContentDisposition.inline().filename(inv.getInvoiceNumber() + ".pdf").build());

        return new ResponseEntity<>(pdfBytes, headers, HttpStatus.OK);
    }

    @PostMapping("/import")
    @PreAuthorize("hasAuthority('CREATE_INVOICE')")
    public ResponseEntity<InvoiceImportResult> importInvoices(@RequestParam("file") MultipartFile file) {
        return ResponseEntity.ok(invoiceService.importInvoices(file, null));
    }

    @GetMapping("/import/template")
    @PreAuthorize("hasAuthority('VIEW_INVOICE')")
    public ResponseEntity<byte[]> downloadTemplate() {
        String csv = "Invoice Number,Customer,Invoice Date,Due Date,Status,Payment Terms,Tax,Currency,Item Description,Quantity,Unit Price,Notes\n"
                   + "INV-2026-1001,John Doe,2026-07-01,2026-07-15,Unpaid,Due On Receipt,5,BDT,Consulting - Phase 1,1,50000,First installment\n"
                   + "INV-2026-1001,John Doe,2026-07-01,2026-07-15,Unpaid,Due On Receipt,5,BDT,Consulting - Phase 2,1,30000,Second installment\n"
                   + ",Jane Smith,2026-07-05,,Draft,Net 15,0,BDT,Website maintenance,2,10000,\n";
        byte[] bytes = csv.getBytes(StandardCharsets.UTF_8);
        return ResponseEntity.ok()
                .header("Content-Disposition", "attachment; filename=invoice_import_template.csv")
                .contentType(MediaType.parseMediaType("text/csv"))
                .body(bytes);
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAuthority('EDIT_INVOICE')")
    public ResponseEntity<InvoiceDto> update(
            @PathVariable Long id,
            @RequestBody UpdateInvoiceRequest req) {
        return ResponseEntity.ok(invoiceService.update(id, req));
    }

    @PutMapping("/{id}/status")
    @PreAuthorize("hasAuthority('EDIT_INVOICE')")
    public ResponseEntity<String> setStatus(
            @PathVariable Long id,
            @RequestBody Map<String, String> body) {
        invoiceService.setStatus(id, body.get("status"));
        return ResponseEntity.ok("Status updated");
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasAuthority('DELETE_INVOICE')")
    public ResponseEntity<String> delete(@PathVariable Long id) {
        invoiceService.delete(id);
        return ResponseEntity.ok("Invoice deleted");
    }
}