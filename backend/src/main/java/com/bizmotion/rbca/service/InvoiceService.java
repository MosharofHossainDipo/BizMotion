package com.bizmotion.rbca.service;

import com.bizmotion.rbca.dto.*;
import com.bizmotion.rbca.entity.Customer;
import com.bizmotion.rbca.entity.Invoice;
import com.bizmotion.rbca.entity.InvoiceItem;
import com.bizmotion.rbca.repository.CustomerRepository;
import com.bizmotion.rbca.repository.InvoiceRepository;
import com.bizmotion.rbca.repository.PaymentRepository;
import org.apache.commons.csv.CSVFormat;
import org.apache.commons.csv.CSVParser;
import org.apache.commons.csv.CSVRecord;
import org.apache.poi.ss.usermodel.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

import java.io.IOException;
import java.io.InputStreamReader;
import java.io.Reader;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.time.Year;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.stream.Collectors; 

@Service
public class InvoiceService {

    @Autowired private InvoiceRepository  repo;
    @Autowired private CustomerRepository customerRepo;
    @Autowired private PaymentRepository  payRepo;

    private static final DateTimeFormatter TRACKING_DATE_FMT = DateTimeFormatter.ofPattern("yyMMdd");

    public List<InvoiceDto> getAll() {
        return repo.findAll().stream()
                .sorted((a, b) -> b.getId().compareTo(a.getId())) // newest first
                .map(this::toDto).collect(Collectors.toList());
    }

    public InvoiceDto getById(Long id) {
        return toDto(repo.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Invoice not found")));
    }

    @Transactional
    public InvoiceDto create(CreateInvoiceRequest req, boolean finalize, Long callerId) {
        Customer customer = customerRepo.findById(req.getCustomerId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Customer not found"));

        Invoice inv = new Invoice();
        inv.setInvoiceNumber(generateInvoiceNumber(req.getPrefix()));
        inv.setSubject(req.getSubject());
        inv.setCustomer(customer);
        inv.setBillingAddress(req.getBillingAddress());
        inv.setInvoiceType(req.getInvoiceType() != null ? req.getInvoiceType() : "Onetime");
        inv.setCurrency(req.getCurrency() != null ? req.getCurrency() : "BDT");
        inv.setPaymentTerms(req.getPaymentTerms());
        inv.setTaxPercent(nz(req.getTaxPercent(), BigDecimal.ZERO));
        inv.setInvoiceDate(req.getInvoiceDate());
        inv.setDueDate(req.getDueDate());
        inv.setNotesToCustomer(req.getNotesToCustomer());
        inv.setInternalRemarks(req.getInternalRemarks());
        inv.setStatus(finalize ? "Unpaid" : "Draft");
        inv.setCreatedBy(callerId);

        applyItems(inv, req.getItems());
        recalculateTotals(inv);

        Invoice saved = repo.save(inv);

        // trackingNumber depends on the DB-assigned id, so it's generated
        // and persisted in a second save right after the first one.
        saved.setTrackingNumber(generateTrackingNumber(saved));
        saved = repo.save(saved);

        return toDto(saved);
    }

    /** Duplicates an existing invoice into a brand-new Draft invoice with a
     *  fresh invoice number — same customer, same line items, today's date,
     *  no due date, status reset to Draft. Used by the "Clone Invoice" button. */
    @Transactional
    public InvoiceDto clone(Long id, Long callerId) {
        Invoice original = repo.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Invoice not found"));

        Invoice copy = new Invoice();
        copy.setInvoiceNumber(generateInvoiceNumber(null));
        copy.setSubject(original.getSubject());
        copy.setCustomer(original.getCustomer());
        copy.setBillingAddress(original.getBillingAddress());
        copy.setInvoiceType(original.getInvoiceType());
        copy.setCurrency(original.getCurrency());
        copy.setPaymentTerms(original.getPaymentTerms());
        copy.setTaxPercent(original.getTaxPercent());
        copy.setInvoiceDate(LocalDate.now());
        copy.setDueDate(null);
        copy.setNotesToCustomer(original.getNotesToCustomer());
        copy.setInternalRemarks(original.getInternalRemarks());
        copy.setStatus("Draft");
        copy.setCreatedBy(callerId);

        int order = 0;
        for (InvoiceItem src : original.getItems()) {
            InvoiceItem item = new InvoiceItem();
            item.setInvoice(copy);
            item.setDescription(src.getDescription());
            item.setQty(src.getQty());
            item.setUnitPrice(src.getUnitPrice());
            item.setSortOrder(order++);
            copy.getItems().add(item);
        }

        recalculateTotals(copy); // also fills each item's lineTotal

        Invoice saved = repo.save(copy);
        saved.setTrackingNumber(generateTrackingNumber(saved));
        saved = repo.save(saved);

        return toDto(saved);
    }

    @Transactional
    public InvoiceDto update(Long id, UpdateInvoiceRequest req) {
        Invoice inv = repo.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Invoice not found"));

        if (req.getCustomerId() != null) {
            Customer customer = customerRepo.findById(req.getCustomerId())
                    .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Customer not found"));
            inv.setCustomer(customer);
        }
        if (req.getSubject()         != null) inv.setSubject(req.getSubject());
        if (req.getBillingAddress()  != null) inv.setBillingAddress(req.getBillingAddress());
        if (req.getInvoiceType()     != null) inv.setInvoiceType(req.getInvoiceType());
        if (req.getCurrency()        != null) inv.setCurrency(req.getCurrency());
        if (req.getPaymentTerms()    != null) inv.setPaymentTerms(req.getPaymentTerms());
        if (req.getTaxPercent()      != null) inv.setTaxPercent(req.getTaxPercent());
        if (req.getInvoiceDate()     != null) inv.setInvoiceDate(req.getInvoiceDate());
        if (req.getDueDate()         != null) inv.setDueDate(req.getDueDate());
        if (req.getNotesToCustomer() != null) inv.setNotesToCustomer(req.getNotesToCustomer());
        if (req.getInternalRemarks() != null) inv.setInternalRemarks(req.getInternalRemarks());

        if (req.getItems() != null) {
            inv.getItems().clear();
            applyItems(inv, req.getItems());
        }
        recalculateTotals(inv);

        return toDto(repo.save(inv));
    }

    @Transactional
    public void setStatus(Long id, String status) {
        List<String> allowed = List.of("Draft", "Unpaid", "Partially Paid", "Paid", "Cancelled");
        if (!allowed.contains(status)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invalid status: " + status);
        }
        Invoice inv = repo.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Invoice not found"));
        inv.setStatus(status);
        repo.save(inv);
    }

    @Transactional
    public void delete(Long id) {
        if (!repo.existsById(id))
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Invoice not found");
        repo.deleteById(id);
    }

    // ==================== IMPORT ====================

    private static final List<String> ALLOWED_STATUSES =
            List.of("Draft", "Unpaid", "Partially Paid", "Paid", "Cancelled");

    @Transactional
    public InvoiceImportResult importInvoices(MultipartFile file, Long callerId) {
        List<Map<String, String>> rows;
        try {
            rows = parseRows(file);
        } catch (IllegalArgumentException e) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, e.getMessage());
        } catch (Exception e) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Could not read file: " + e.getMessage());
        }

        if (rows.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "File contains no data rows.");
        }

        Set<String> headers = rows.get(0).keySet();
        boolean hasCustomerCol = headers.contains("customer") || headers.contains("customerid")
                || headers.contains("customercode") || headers.contains("customeremail");
        boolean hasItemCols = headers.contains("itemdescription") && headers.contains("quantity") && headers.contains("unitprice");
        if (!hasCustomerCol || !hasItemCols) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "File is missing required columns: Customer and/or Item Description/Quantity/Unit Price.");
        }

        // Group rows into invoices: rows sharing a non-blank Invoice Number
        // are merged into one invoice with multiple line items. Rows with a
        // blank Invoice Number each become their own single-item invoice.
        LinkedHashMap<String, List<Integer>> groups = new LinkedHashMap<>();
        for (int i = 0; i < rows.size(); i++) {
            String invNum = nz(rows.get(i).get("invoicenumber"));
            String key = invNum.isBlank() ? "__row_" + i : "num_" + invNum;
            groups.computeIfAbsent(key, k -> new ArrayList<>()).add(i);
        }

        List<String> errors = new ArrayList<>();
        List<Invoice> toSave = new ArrayList<>();
        Set<String> seenNumbers = new HashSet<>();
        int duplicates = 0, invalid = 0;

        for (List<Integer> idxs : groups.values()) {
            int firstRowNum = idxs.get(0) + 2; // +2: header is row 1, data is 0-based
            Map<String, String> first = rows.get(idxs.get(0));
            List<String> groupErrors = new ArrayList<>();

            Customer customer = matchCustomer(first);
            if (customer == null) groupErrors.add("Customer not found");

            LocalDate invoiceDate = parseDate(first.get("invoicedate"));
            if (invoiceDate == null) groupErrors.add("Missing or invalid Invoice Date");

            String explicitNumber = nz(first.get("invoicenumber"));

            List<InvoiceItem> items = new ArrayList<>();
            int order = 0;
            for (int idx : idxs) {
                Map<String, String> row = rows.get(idx);
                int rowNum = idx + 2;
                String desc = nz(row.get("itemdescription"));
                String qtyStr = nz(row.get("quantity"));
                String priceStr = nz(row.get("unitprice"));

                if (desc.isBlank()) {
                    groupErrors.add("Row " + rowNum + ": Missing Item Description");
                    continue;
                }
                BigDecimal qty;
                try {
                    qty = new BigDecimal(qtyStr);
                    if (qty.compareTo(BigDecimal.ZERO) <= 0) throw new NumberFormatException();
                } catch (Exception e) {
                    groupErrors.add("Row " + rowNum + ": Invalid Quantity");
                    continue;
                }
                BigDecimal price;
                try {
                    price = new BigDecimal(priceStr);
                    if (price.compareTo(BigDecimal.ZERO) < 0) throw new NumberFormatException();
                } catch (Exception e) {
                    groupErrors.add("Row " + rowNum + ": Invalid Unit Price");
                    continue;
                }

                InvoiceItem item = new InvoiceItem();
                item.setDescription(desc);
                item.setQty(qty);
                item.setUnitPrice(price);
                item.setSortOrder(order++);
                items.add(item);
            }

            if (items.isEmpty() && groupErrors.isEmpty()) {
                groupErrors.add("No valid line items");
            }

            if (!groupErrors.isEmpty()) {
                errors.add("Row " + firstRowNum + ": " + String.join("; ", groupErrors));
                invalid++;
                continue;
            }

            boolean dup = !explicitNumber.isBlank()
                    && (seenNumbers.contains(explicitNumber) || repo.existsByInvoiceNumber(explicitNumber));
            if (dup) {
                errors.add("Row " + firstRowNum + ": Duplicate invoice number " + explicitNumber);
                duplicates++;
                continue;
            }

            Invoice inv = new Invoice();
            inv.setInvoiceNumber(explicitNumber.isBlank() ? generateInvoiceNumber(null) : explicitNumber);
            inv.setSubject(nz(first.get("subject")).isBlank() ? null : nz(first.get("subject")));
            inv.setCustomer(customer);
            inv.setInvoiceType("Onetime");
            inv.setCurrency(orDefault(first.get("currency"), "BDT"));
            inv.setPaymentTerms(first.get("paymentterms"));
            inv.setInvoiceDate(invoiceDate);
            inv.setDueDate(parseDate(first.get("duedate")));
            inv.setNotesToCustomer(first.get("notes"));

            String statusVal = nz(first.get("status"));
            inv.setStatus(ALLOWED_STATUSES.contains(statusVal) ? statusVal : "Draft");

            BigDecimal tax = BigDecimal.ZERO;
            try {
                String taxStr = nz(first.get("tax"));
                if (!taxStr.isBlank()) tax = new BigDecimal(taxStr);
            } catch (Exception ignored) { /* keep 0 on bad tax value */ }
            inv.setTaxPercent(tax);
            inv.setCreatedBy(callerId);

            for (InvoiceItem it : items) {
                it.setInvoice(inv);
                inv.getItems().add(it);
            }
            recalculateTotals(inv);

            if (!explicitNumber.isBlank()) seenNumbers.add(explicitNumber);
            toSave.add(inv);
        }

        List<Invoice> saved = repo.saveAll(toSave);
        // trackingNumber depends on the DB-assigned id, so it's generated
        // and persisted in a second pass, same as create()/clone().
        for (Invoice inv : saved) {
            inv.setTrackingNumber(generateTrackingNumber(inv));
        }
        repo.saveAll(saved);

        return new InvoiceImportResult(groups.size(), toSave.size(), duplicates, invalid, errors);
    }

    private Customer matchCustomer(Map<String, String> row) {
        String idStr = nz(row.get("customerid"));
        if (!idStr.isBlank()) {
            try {
                Long id = Long.parseLong(idStr);
                Optional<Customer> byId = customerRepo.findById(id);
                if (byId.isPresent()) return byId.get();
            } catch (NumberFormatException ignored) { /* fall through to next match strategy */ }
        }
        String code = nz(row.get("customercode"));
        if (!code.isBlank()) {
            Optional<Customer> byCode = customerRepo.findByCustomerCode(code);
            if (byCode.isPresent()) return byCode.get();
        }
        String email = nz(row.get("customeremail"));
        if (!email.isBlank()) {
            Optional<Customer> byEmail = customerRepo.findByEmailIgnoreCase(email);
            if (byEmail.isPresent()) return byEmail.get();
        }
        String name = nz(row.get("customer"));
        if (!name.isBlank()) {
            Optional<Customer> byName = customerRepo.findByNameIgnoreCase(name);
            if (byName.isPresent()) return byName.get();
        }
        return null;
    }

    private LocalDate parseDate(String s) {
        if (s == null || s.isBlank()) return null;
        String v = s.trim();
        DateTimeFormatter[] formats = {
                DateTimeFormatter.ISO_LOCAL_DATE,
                DateTimeFormatter.ofPattern("dd/MM/yyyy"),
                DateTimeFormatter.ofPattern("MM/dd/yyyy"),
                DateTimeFormatter.ofPattern("yyyy/MM/dd")
        };
        for (DateTimeFormatter f : formats) {
            try { return LocalDate.parse(v, f); } catch (Exception ignored) { /* try next format */ }
        }
        return null;
    }

    private String nz(String s) { return s == null ? "" : s.trim(); }
    private String orDefault(String s, String def) { return (s == null || s.isBlank()) ? def : s.trim(); }

    private List<Map<String, String>> parseRows(MultipartFile file) throws IOException {
        String filename = file.getOriginalFilename() != null ? file.getOriginalFilename().toLowerCase() : "";
        if (filename.endsWith(".csv")) return parseCsv(file);
        if (filename.endsWith(".xlsx") || filename.endsWith(".xls")) return parseExcel(file);
        throw new IllegalArgumentException("Unsupported file type. Please upload .csv, .xlsx, or .xls");
    }

    private List<Map<String, String>> parseCsv(MultipartFile file) throws IOException {
        List<Map<String, String>> result = new ArrayList<>();
        try (Reader reader = new InputStreamReader(file.getInputStream(), StandardCharsets.UTF_8)) {
            CSVParser parser = CSVFormat.DEFAULT.builder()
                    .setHeader().setSkipHeaderRecord(true).setTrim(true)
                    .build().parse(reader);
            List<String> headers = parser.getHeaderNames().stream()
                    .map(this::normalizeHeader).collect(Collectors.toList());
            for (CSVRecord rec : parser) {
                Map<String, String> row = new HashMap<>();
                for (int i = 0; i < headers.size(); i++) {
                    if (i < rec.size()) row.put(headers.get(i), rec.get(i));
                }
                result.add(row);
            }
        }
        return result;
    }

    private List<Map<String, String>> parseExcel(MultipartFile file) throws IOException {
        List<Map<String, String>> result = new ArrayList<>();
        try (Workbook wb = WorkbookFactory.create(file.getInputStream())) {
            Sheet sheet = wb.getSheetAt(0);
            Row headerRow = sheet.getRow(0);
            if (headerRow == null) return result;

            List<String> headers = new ArrayList<>();
            for (Cell cell : headerRow) headers.add(normalizeHeader(cellToString(cell)));

            for (int r = 1; r <= sheet.getLastRowNum(); r++) {
                Row row = sheet.getRow(r);
                if (row == null) continue;
                boolean allBlank = true;
                Map<String, String> map = new HashMap<>();
                for (int c = 0; c < headers.size(); c++) {
                    Cell cell = row.getCell(c);
                    String val = cellToString(cell);
                    if (!val.isBlank()) allBlank = false;
                    map.put(headers.get(c), val);
                }
                if (!allBlank) result.add(map);
            }
        }
        return result;
    }

    private String cellToString(Cell cell) {
        if (cell == null) return "";
        return switch (cell.getCellType()) {
            case STRING -> cell.getStringCellValue().trim();
            case NUMERIC -> DateUtil.isCellDateFormatted(cell)
                    ? cell.getLocalDateTimeCellValue().toLocalDate().toString()
                    : stripTrailingZero(cell.getNumericCellValue());
            case BOOLEAN -> String.valueOf(cell.getBooleanCellValue());
            case FORMULA -> cell.getCellFormula();
            default -> "";
        };
    }

    private String stripTrailingZero(double d) {
        if (d == Math.floor(d) && !Double.isInfinite(d)) return String.valueOf((long) d);
        return String.valueOf(d);
    }

    private String normalizeHeader(String h) {
        return h == null ? "" : h.trim().toLowerCase().replaceAll("[^a-z0-9]", "");
    }

    // ==================== helpers ====================

    private void applyItems(Invoice inv, List<CreateInvoiceItemRequest> itemReqs) {
        if (itemReqs == null || itemReqs.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "At least one line item is required");
        }
        int order = 0;
        for (CreateInvoiceItemRequest ir : itemReqs) {
            InvoiceItem item = new InvoiceItem();
            item.setInvoice(inv);
            item.setDescription(ir.getDescription());
            item.setQty(nz(ir.getQty(), BigDecimal.ONE));
            item.setUnitPrice(nz(ir.getUnitPrice(), BigDecimal.ZERO));
            item.setSortOrder(order++);
            item.setLineTotal(item.getQty().multiply(item.getUnitPrice()).setScale(2, RoundingMode.HALF_UP));
            inv.getItems().add(item);
        }
    }

    /** Recomputes subtotal (sum of qty*unitPrice, no discount) and applies
     *  the single invoice-level tax rate on top. Client-submitted totals
     *  are never trusted. */
    private void recalculateTotals(Invoice inv) {
        BigDecimal subtotal = BigDecimal.ZERO;

        for (InvoiceItem item : inv.getItems()) {
            BigDecimal lineTotal = item.getQty().multiply(item.getUnitPrice()).setScale(2, RoundingMode.HALF_UP);
            item.setLineTotal(lineTotal);
            subtotal = subtotal.add(lineTotal);
        }

        BigDecimal taxTotal = subtotal
                .multiply(nz(inv.getTaxPercent(), BigDecimal.ZERO))
                .divide(BigDecimal.valueOf(100), 4, RoundingMode.HALF_UP)
                .setScale(2, RoundingMode.HALF_UP);

        inv.setSubtotal(subtotal.setScale(2, RoundingMode.HALF_UP));
        inv.setTaxTotal(taxTotal);
        inv.setGrandTotal(subtotal.add(taxTotal).setScale(2, RoundingMode.HALF_UP));
    }

    private BigDecimal nz(BigDecimal v, BigDecimal fallback) { return v != null ? v : fallback; }

    /** Uses MAX(id)+1 rather than COUNT(*) so a deleted invoice can never cause
     *  a duplicate-number collision. */
    private String generateInvoiceNumber(String prefix) {
        String p = (prefix == null || prefix.isBlank()) ? "INV-" : prefix;
        int year = Year.now().getValue();
        long nextSeq = repo.findMaxId() + 1;
        String candidate;
        do {
            candidate = String.format("%s%d-%04d", p, year, nextSeq);
            nextSeq++;
        } while (repo.existsByInvoiceNumber(candidate));
        return candidate;
    }

    /** yyMMdd (from the invoice date) + the DB id zero-padded to 5 digits,
     *  e.g. "26032900009" — matches the reference PDF's "Tracking No" format. */
    private String generateTrackingNumber(Invoice inv) {
        String datePart = inv.getInvoiceDate().format(TRACKING_DATE_FMT);
        return datePart + String.format("%05d", inv.getId());
    }

    private InvoiceDto toDto(Invoice inv) {
        List<InvoiceItemDto> items = inv.getItems().stream()
                .map(i -> new InvoiceItemDto(i.getId(), i.getDescription(), i.getQty(), i.getUnitPrice(),
                        i.getLineTotal(), i.getSortOrder()))
                .collect(Collectors.toList());

        BigDecimal totalPaid = payRepo.sumByInvoiceId(inv.getId());
        BigDecimal remainingBalance = inv.getGrandTotal().subtract(totalPaid);

        return new InvoiceDto(
                inv.getId(), inv.getInvoiceNumber(), inv.getTrackingNumber(), inv.getSubject(),
                inv.getCustomer().getId(), inv.getCustomer().getName(),
                inv.getBillingAddress(), inv.getStatus(), inv.getInvoiceType(), inv.getCurrency(),
                inv.getPaymentTerms(), inv.getInvoiceDate(), inv.getDueDate(),
                inv.getTaxPercent(), inv.getSubtotal(), inv.getTaxTotal(), inv.getGrandTotal(),
                totalPaid, remainingBalance,
                inv.getNotesToCustomer(), inv.getInternalRemarks(),
                inv.getCreatedBy(), inv.getCreatedAt(), inv.getUpdatedAt(), items
        );
    }
}
