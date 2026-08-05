import { Component, OnInit, ChangeDetectorRef } from "@angular/core";
import { CommonModule } from "@angular/common";
import { FormsModule } from "@angular/forms";
import { Router } from "@angular/router";
import { InvoiceService, InvoiceDto } from "../../services/invoice.service";
import { CustomerService, CustomerDto } from "../../services/customer.service";

@Component({
  selector: "app-payments",
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: "./payments.component.html",
  styleUrls: ["./payments.component.css"]
})
export class PaymentsComponent implements OnInit {

  loading = true;
  error = "";

  invoices: InvoiceDto[] = [];
  customers: CustomerDto[] = [];

  dateFrom = "";
  dateTo = "";
  customerId: number | "all" = "all";
  statusFilter: "all" | "Unpaid" | "Partially Paid" = "all";
  searchTerm = "";

  page = 1;
  pageSize = 10;
  Math=Math;

  constructor(
    private router: Router,
    private invoiceService: InvoiceService,
    private customerService: CustomerService,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    this.load();
    this.customerService.getAll().subscribe({
      next: (data) => { this.customers = data; this.cdr.detectChanges(); },
      error: () => {}
    });
  }

  load(): void {
    this.loading = true;
    this.error = "";
    this.invoiceService.getAll().subscribe({
      next: (data) => {
        this.invoices = (data || []).filter(inv => inv.status === "Unpaid" || inv.status === "Partially Paid");
        this.loading = false;
        this.cdr.detectChanges();
      },
      error: (err) => {
        this.loading = false;
        this.error = err.status === 0
          ? "Cannot connect to backend. Make sure the Spring Boot server is running on port 8080."
          : (err?.error?.error || "Failed to load payments.");
        this.cdr.detectChanges();
      }
    });
  }

  get filtered(): InvoiceDto[] {
    return this.invoices.filter(inv => {
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

  applyFilters(): void {
    this.page = 1;
  }

  goToPage(p: number): void {
    if (p < 1 || p > this.totalPages) return;
    this.page = p;
  }

  viewInvoice(inv: InvoiceDto): void {
    this.router.navigate(["/sales/invoices", inv.id]);
  }

  statusClass(status: string): string {
    return status === "Partially Paid" ? "badge-partial" : "badge-unpaid";
  }
}
