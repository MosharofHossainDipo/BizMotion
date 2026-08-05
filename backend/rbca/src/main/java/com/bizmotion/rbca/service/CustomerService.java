package com.bizmotion.rbca.service;

import com.bizmotion.rbca.dto.CreateCustomerRequest;
import com.bizmotion.rbca.dto.CustomerDto;
import com.bizmotion.rbca.dto.CustomerImportResult;
import com.bizmotion.rbca.dto.UpdateCustomerRequest;
import com.bizmotion.rbca.entity.Customer;
import com.bizmotion.rbca.repository.CustomerRepository;
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
import java.nio.charset.StandardCharsets;
import java.time.Year;
import java.util.*;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

@Service
public class CustomerService {

    @Autowired private CustomerRepository repo;

    private static final Pattern EMAIL_RE = Pattern.compile("^[\\w.+-]+@[\\w-]+\\.[a-zA-Z]{2,}$");

    public List<CustomerDto> getAll() {
        return repo.findAll().stream()
                .sorted((a,b) -> a.getId().compareTo(b.getId()))
                .map(this::toDto).collect(Collectors.toList());
    }

    public CustomerDto getById(Long id) {
        return toDto(repo.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Customer not found")));
    }

    @Transactional
    public CustomerDto create(CreateCustomerRequest req, Long callerId) {
        if (repo.existsByEmail(req.getEmail()))
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Email already registered");
        Customer c = new Customer();
        c.setCustomerCode(generateCode());
        c.setName(req.getName());
        c.setCustomerType(req.getCustomerType());
        c.setEmail(req.getEmail());
        c.setIndustry(req.getIndustry());
        c.setPhone(req.getPhone());
        c.setCompany(req.getCompany());
        c.setWebsite(req.getWebsite());
        c.setAddress(req.getAddress());
        c.setCustomerGroup(req.getCustomerGroup());
        c.setPreferredLanguage(req.getPreferredLanguage());
        c.setNotes(req.getNotes());
        c.setPortalAccess(req.isPortalAccess());
        c.setPortalUsername(req.getPortalUsername());
        c.setStatus("Active");
        c.setCreatedBy(callerId);
        return toDto(repo.save(c));
    }

    @Transactional
    public CustomerDto update(Long id, UpdateCustomerRequest req) {
        Customer c = repo.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Customer not found"));
        c.setName(req.getName()); c.setCustomerType(req.getCustomerType());
        c.setEmail(req.getEmail()); c.setIndustry(req.getIndustry());
        c.setPhone(req.getPhone()); c.setCompany(req.getCompany());
        c.setWebsite(req.getWebsite()); c.setAddress(req.getAddress());
        c.setCustomerGroup(req.getCustomerGroup());
        c.setPreferredLanguage(req.getPreferredLanguage());
        c.setNotes(req.getNotes());
        c.setPortalAccess(req.isPortalAccess());
        c.setPortalUsername(req.getPortalUsername());
        return toDto(repo.save(c));
    }

    @Transactional
    public void setStatus(Long id, boolean active) {
        Customer c = repo.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Customer not found"));
        c.setStatus(active ? "Active" : "Inactive");
        repo.save(c);
    }

    @Transactional
    public void delete(Long id) {
        if (!repo.existsById(id))
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Customer not found");
        repo.deleteById(id);
    }

    @Transactional
    public CustomerImportResult importCustomers(MultipartFile file, Long callerId) {
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
        if (!headers.contains("customername") || !headers.contains("email")) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "File is missing required columns: Customer Name and/or Email.");
        }

        List<String> errors = new ArrayList<>();
        List<Customer> toSave = new ArrayList<>();
        Set<String> seenEmails = new HashSet<>();
        Set<String> seenCodes = new HashSet<>();
        int duplicates = 0, invalid = 0;
        int codeYear = Year.now().getValue();
        String codePrefix = "CUS-" + codeYear + "-";
        long nextCodeSeq = repo.findCodesWithPrefix(codePrefix).stream()
                .map(c -> c.substring(codePrefix.length()))
                .filter(s -> s.matches("\\d+"))
                .mapToLong(Long::parseLong)
                .max()
                .orElse(0L) + 1;

        int rowNum = 1; // row 1 is the header
        for (Map<String, String> row : rows) {
            rowNum++;
            String name  = nz(row.get("customername"));
            String email = nz(row.get("email"));
            String code  = nz(row.get("customercode"));

            List<String> rowErrors = new ArrayList<>();
            if (name.isBlank())  rowErrors.add("Missing Customer Name");
            if (email.isBlank()) rowErrors.add("Missing Email");
            else if (!EMAIL_RE.matcher(email).matches()) rowErrors.add("Invalid Email format");

            if (!rowErrors.isEmpty()) {
                errors.add("Row " + rowNum + ": " + String.join("; ", rowErrors));
                invalid++;
                continue;
            }

            String emailKey = email.toLowerCase();
            boolean dup = seenEmails.contains(emailKey) || repo.existsByEmail(email);
            if (!code.isBlank() && (seenCodes.contains(code) || repo.existsByCustomerCode(code))) {
                dup = true;
            }
            if (dup) {
                errors.add("Row " + rowNum + ": Duplicate customer (email or code already exists)");
                duplicates++;
                continue;
            }

            Customer c = new Customer();
            c.setCustomerCode(code.isBlank() ? String.format("CUS-%d-%04d", codeYear,  nextCodeSeq++) : code);
            c.setName(name);
            c.setEmail(email);
            c.setCustomerType(orDefault(row.get("customertype"), "Individual"));
            c.setIndustry(row.get("industry"));
            c.setPhone(row.get("phone"));
            c.setCompany(row.get("company"));
            c.setWebsite(row.get("website"));
            c.setAddress(row.get("address"));
            c.setCustomerGroup(row.get("group"));
            c.setPreferredLanguage(row.get("preferredlanguage"));
            c.setNotes(row.get("notes"));
            c.setPortalAccess(false);
            c.setStatus(orDefault(row.get("status"), "Active"));
            c.setCreatedBy(callerId);

            seenEmails.add(emailKey);
            if (!code.isBlank()) seenCodes.add(code);
            toSave.add(c);
        }

        repo.saveAll(toSave);

        return new CustomerImportResult(rows.size(), toSave.size(), duplicates, invalid, errors);
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

    private String generateCode() {
        int year = Year.now().getValue();
        long seq  = repo.count() + 1;
        return String.format("CUS-%d-%04d", year, seq);
    }

    private CustomerDto toDto(Customer c) {
        return new CustomerDto(c.getId(), c.getCustomerCode(), c.getName(),
            c.getCustomerType(), c.getIndustry(), c.getEmail(), c.getPhone(),
            c.getCompany(), c.getWebsite(), c.getAddress(), c.getCustomerGroup(),
            c.getPreferredLanguage(), c.getNotes(), c.isPortalAccess(),
            c.getPortalUsername(), c.getStatus(), c.getCreatedBy(),
            c.getCreatedAt(), c.getUpdatedAt());
    }
}