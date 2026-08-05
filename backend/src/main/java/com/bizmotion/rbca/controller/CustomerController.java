package com.bizmotion.rbca.controller;

import com.bizmotion.rbca.dto.CreateCustomerRequest;
import com.bizmotion.rbca.dto.CustomerDto;
import com.bizmotion.rbca.dto.CustomerImportResult;
import com.bizmotion.rbca.dto.UpdateCustomerRequest;
import com.bizmotion.rbca.service.CustomerService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/customers")
public class CustomerController {

    @Autowired
    private CustomerService customerService;

    @GetMapping
    @PreAuthorize("hasAuthority('VIEW_CUSTOMER')")
    public ResponseEntity<List<CustomerDto>> getAll() {
        return ResponseEntity.ok(customerService.getAll());
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasAuthority('VIEW_CUSTOMER')")
    public ResponseEntity<CustomerDto> getById(@PathVariable Long id) {
        return ResponseEntity.ok(customerService.getById(id));
    }

    @PostMapping
    @PreAuthorize("hasAuthority('CREATE_CUSTOMER')")
    public ResponseEntity<CustomerDto> create(
            @RequestBody @Valid CreateCustomerRequest req,
            Authentication auth) {
        return ResponseEntity.status(201).body(customerService.create(req, null));
    }

    @PostMapping("/import")
    @PreAuthorize("hasAuthority('CREATE_CUSTOMER')")
    public ResponseEntity<CustomerImportResult> importCustomers(@RequestParam("file") MultipartFile file) {
        return ResponseEntity.ok(customerService.importCustomers(file, null));
    }

    @GetMapping("/import/template")
    @PreAuthorize("hasAuthority('VIEW_CUSTOMER')")
    public ResponseEntity<byte[]> downloadTemplate() {
        String csv = "Customer Name,Customer Code,Email,Phone,Company,Group,Address,Industry,Website,Customer Type,Preferred Language,Status,Notes\n"
                   + "John Doe,,john@example.com,+8801700000000,Acme Ltd,VIP,123 Main St,Tech,https://acme.com,Individual,English,Active,Sample note\n";
        byte[] bytes = csv.getBytes(StandardCharsets.UTF_8);
        return ResponseEntity.ok()
                .header("Content-Disposition", "attachment; filename=customer_import_template.csv")
                .contentType(MediaType.parseMediaType("text/csv"))
                .body(bytes);
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAuthority('EDIT_CUSTOMER')")
    public ResponseEntity<CustomerDto> update(
            @PathVariable Long id,
            @RequestBody @Valid UpdateCustomerRequest req) {
        return ResponseEntity.ok(customerService.update(id, req));
    }

    @PutMapping("/{id}/status")
    @PreAuthorize("hasAuthority('EDIT_CUSTOMER')")
    public ResponseEntity<String> setStatus(
            @PathVariable Long id,
            @RequestBody Map<String, Boolean> body) {
        customerService.setStatus(id, Boolean.TRUE.equals(body.get("active")));
        return ResponseEntity.ok("Status updated");
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasAuthority('DELETE_CUSTOMER')")
    public ResponseEntity<String> delete(@PathVariable Long id) {
        customerService.delete(id);
        return ResponseEntity.ok("Customer deleted");
    }
}