import { Component, OnInit, ChangeDetectorRef } from "@angular/core";
import { CommonModule } from "@angular/common";
import { FormsModule } from "@angular/forms";
import { Router } from "@angular/router";
import { InvoiceService, InvoiceDto, InvoiceImportResult } from "../../services/invoice.service";
import { CustomerService, CustomerDto } from "../../services/customer.service";

@Component({
  selector: "app-invoices",
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: "./invoices.component.html",
  styleUrls: ["./invoices.component.css"]
})
export class InvoicesComponent implements OnInit {

  loading = true;
  error   = "";

  invoices: InvoiceDto[] = [];
  customers: CustomerDto[] = [];

  // filters
  dateFrom = "";
  dateTo   = "";
  customerId: number | "all" = "all";
  statusFilter = "all";
  searchTerm = "";
  activeTab: "all" | "Unpaid" | "Partially Paid" | "Paid" | "Cancelled" = "all";

  // pagination (client-side)
  page = 1;
  pageSize = 10;

  showImportModal = false;
  importing = false;
  importError = "";
  importResult: InvoiceImportResult | null = null;
  selectedFile: File | null = null;
  isDragOver = false;

  private avatarPalette = [
    { bg: "#d0e1fb", fg: "#54647a" },
    { bg: "#ffdbc7", fg: "#733600" },
    { bg: "#d6e3ff", fg: "#08458b" },
    { bg: "rgba(16,185,129,0.18)", fg: "#0f7a56" },
    { bg: "#ffe8b3", fg: "#8a5a00" }
  ];

  constructor(
    private router: Router,
    private invoiceService: InvoiceService,
    private customerService: CustomerService,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    const today = new Date();
    const monthAgo = new Date();
    monthAgo.setDate(today.getDate() - 30);
    this.dateFrom = monthAgo.toISOString().slice(0, 10);
    this.dateTo   = today.toISOString().slice(0, 10);

    this.loadInvoices();
    this.customerService.getAll().subscribe({
      next: (data) => { this.customers = data; this.cdr.detectChanges(); },
      error: () => {} // filter dropdown just stays empty on failure, non-fatal
    });
  }

  loadInvoices(): void {
    this.loading = true;
    this.error = "";
    this.invoiceService.getAll().subscribe({
      next: (data) => {
        // Defensive normalization — keeps rendering safe even if a field is
        // missing, though the real root cause of the "stuck loading" bug was
        // change detection not running after this async callback (fixed via
        // cdr.detectChanges() below).
        this.invoices = (data || []).map(inv => ({
          ...inv,
          customerName: inv.customerName ?? "Unknown Customer",
          status: inv.status ?? "Draft",
          grandTotal: inv.grandTotal ?? 0,
          invoiceNumber: inv.invoiceNumber ?? "—"
        }));
        this.loading = false;
        this.cdr.detectChanges();
      },
      error: (err) => {
        this.loading = false;
        this.error = err.status === 0
          ? "Cannot connect to backend. Make sure the Spring Boot server is running on port 8080."
          : (err?.error?.error || "Failed to load invoices.");
        this.cdr.detectChanges();
      }
    });
  }

  get filtered(): InvoiceDto[] {
    return this.invoices.filter(inv => {
      if (this.activeTab !== "all" && inv.status !== this.activeTab) return false;
      if (this.statusFilter !== "all" && inv.status !== this.statusFilter) return false;
      if (this.customerId !== "all" && inv.customerId !== this.customerId) return false;
      if (this.dateFrom && inv.invoiceDate < this.dateFrom) return false;
      if (this.dateTo && inv.invoiceDate > this.dateTo) return false;
      if (this.searchTerm.trim()) {
        const q = this.searchTerm.trim().toLowerCase();
        const hit = (inv.invoiceNumber || "").toLowerCase().includes(q) ||
                    (inv.customerName || "").toLowerCase().includes(q);
        if (!hit) return false;
      }
      return true;
    });
  }

  get paged(): InvoiceDto[] {
    const start = (this.page - 1) * this.pageSize;
    return this.filtered.slice(start, start + this.pageSize);
  }

  get totalPages(): number {
    return Math.max(1, Math.ceil(this.filtered.length / this.pageSize));
  }

  get pageNumbers(): number[] {
    return Array.from({ length: this.totalPages }, (_, i) => i + 1);
  }

  get rangeStart(): number {
    return this.filtered.length === 0 ? 0 : (this.page - 1) * this.pageSize + 1;
  }

  get rangeEnd(): number {
    return Math.min(this.page * this.pageSize, this.filtered.length);
  }

  setTab(tab: "all" | "Unpaid" | "Partially Paid" | "Paid" | "Cancelled"): void {
    this.activeTab = tab;
    this.page = 1;
  }

  applyFilters(): void {
    this.page = 1;
  }

  goToPage(p: number): void {
    if (p < 1 || p > this.totalPages) return;
    this.page = p;
  }

  addInvoice(): void {
    this.router.navigate(["/sales/new-invoice"]);
  }

  viewInvoice(inv: InvoiceDto): void {
    this.router.navigate(["/sales/invoices", inv.id]);
  }

  editInvoice(inv: InvoiceDto): void {
    // TODO: build invoice edit flow — placeholder for now
    alert(`Editing ${inv.invoiceNumber} is coming soon.`);
  }

  downloadInvoice(inv: InvoiceDto): void {
    window.open(`/invoice-pdf/${inv.id}`, "_blank");
  }

  deleteInvoice(inv: InvoiceDto): void {
    if (!confirm(`Delete invoice ${inv.invoiceNumber}? This cannot be undone.`)) return;
    this.invoiceService.delete(inv.id).subscribe({
      next: () => {
        this.invoices = this.invoices.filter(i => i.id !== inv.id);
        this.cdr.detectChanges();
      },
      error: (err) => {
        alert(err?.error?.error || "Failed to delete invoice.");
      }
    });
  }

  getInitials(name: string | null | undefined): string {
    if (!name || !name.trim()) return "?";
    const parts = name.trim().split(/\s+/);
    return parts.length === 1
      ? parts[0].slice(0, 2).toUpperCase()
      : (parts[0][0] + parts[1][0]).toUpperCase();
  }

  avatarColor(name: string | null | undefined): { bg: string; fg: string } {
    const safeName = name || "?";
    let hash = 0;
    for (let i = 0; i < safeName.length; i++) hash = safeName.charCodeAt(i) + ((hash << 5) - hash);
    return this.avatarPalette[Math.abs(hash) % this.avatarPalette.length];
  }

  statusClass(status: string): string {
    switch (status) {
      case "Paid":            return "badge-paid";
      case "Unpaid":          return "badge-unpaid";
      case "Partially Paid":  return "badge-partial";
      case "Cancelled":       return "badge-cancelled";
      default:                return "badge-draft";
    }
  }

  isOverdue(inv: InvoiceDto): boolean {
    if (!inv.dueDate || inv.status === "Paid" || inv.status === "Cancelled") return false;
    return inv.dueDate < new Date().toISOString().slice(0, 10);
  }

  openImportModal(): void {
    this.showImportModal = true;
    this.selectedFile = null;
    this.importError = "";
    this.importResult = null;
  }

  closeImportModal(): void {
    if (this.importing) return;
    this.showImportModal = false;
  }

  onFileSelected(event: Event): void {
    const input = event.target as HTMLInputElement;
    if (input.files && input.files.length > 0) {
      this.selectedFile = input.files[0];
      this.importError = "";
    }
  }

  onDragOver(event: DragEvent): void {
    event.preventDefault();
    this.isDragOver = true;
  }

  onDragLeave(event: DragEvent): void {
    event.preventDefault();
    this.isDragOver = false;
  }

  onDrop(event: DragEvent): void {
    event.preventDefault();
    this.isDragOver = false;
    if (event.dataTransfer?.files?.length) {
      this.selectedFile = event.dataTransfer.files[0];
      this.importError = "";
    }
  }

  downloadTemplate(): void {
    this.invoiceService.downloadTemplate().subscribe({
      next: (blob) => {
        const url = window.URL.createObjectURL(blob);
        const a = document.createElement("a");
        a.href = url;
        a.download = "invoice_import_template.csv";
        a.click();
        window.URL.revokeObjectURL(url);
      },
      error: () => alert("Failed to download template.")
    });
  }

  runImport(): void {
    if (!this.selectedFile) {
      this.importError = "Please select a file first.";
      this.cdr.detectChanges();
      return;
    }
    this.importing = true;
    this.importError = "";
    this.importResult = null;
    this.cdr.detectChanges();

    this.invoiceService.importInvoices(this.selectedFile).subscribe({
      next: (result) => {
        this.importing = false;
        this.importResult = result;
        this.cdr.detectChanges();
        if (result.imported > 0) this.loadInvoices();
      },
      error: (err) => {
        this.importing = false;
        this.importError = err?.error?.error || err?.error?.message || "Import failed.";
        this.cdr.detectChanges();
      }
    });
  }
}