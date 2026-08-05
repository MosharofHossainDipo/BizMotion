import { Component, OnInit, ChangeDetectorRef } from "@angular/core";
import { CommonModule } from "@angular/common";
import { FormsModule } from "@angular/forms";
import { AccountService, AccountDto } from "../../services/account.service";
import { TransactionService, TransactionDto, TransactionLookups } from "../../services/transaction.service";

@Component({
  selector: "app-view-transactions",
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: "./view-transactions.component.html",
  styleUrls: ["./view-transactions.component.css"]
})
export class ViewTransactionsComponent implements OnInit {

  accounts: AccountDto[] = [];
  lookups: TransactionLookups = { types: [], contacts: [], companies: [], categories: [], staff: [], paymentMethods: [] };

  transactions: TransactionDto[] = [];
  loading = true;
  error = "";

  page = 1;
  pageSize = 10;
  Math = Math;

  filters = {
    dateFrom: "",
    dateTo: new Date().toISOString().slice(0, 10),
    type: "all",
    accountId: "all" as number | "all",
    contact: "all",
    company: "all",
    category: "all",
    staff: "all",
    paymentMethod: "all"
  };

  constructor(
    private accountService: AccountService,
    private transactionService: TransactionService,
    private cdr: ChangeDetectorRef
  ) {
    const monthAgo = new Date();
    monthAgo.setDate(monthAgo.getDate() - 30);
    this.filters.dateFrom = monthAgo.toISOString().slice(0, 10);
  }

  ngOnInit(): void {
    this.accountService.getAll().subscribe({
      next: (data) => { this.accounts = data; this.cdr.detectChanges(); },
      error: () => {}
    });
    this.transactionService.getLookups().subscribe({
      next: (data) => { this.lookups = data; this.cdr.detectChanges(); },
      error: () => {}
    });
    this.load();
  }

  load(): void {
    this.loading = true;
    this.error = "";
    this.page = 1;
    const accountId = this.filters.accountId === "all" ? undefined : this.filters.accountId as number;
    this.transactionService.getAll({
      dateFrom: this.filters.dateFrom,
      dateTo: this.filters.dateTo,
      type: this.filters.type,
      accountId,
      contact: this.filters.contact,
      company: this.filters.company,
      category: this.filters.category,
      staff: this.filters.staff,
      paymentMethod: this.filters.paymentMethod
    }).subscribe({
      next: (data) => {
        this.transactions = data;
        this.loading = false;
        this.cdr.detectChanges();
      },
      error: (err) => {
        this.loading = false;
        this.error = err?.error?.error || "Failed to load transactions.";
        this.cdr.detectChanges();
      }
    });
  }

  get paged(): TransactionDto[] {
    const start = (this.page - 1) * this.pageSize;
    return this.transactions.slice(start, start + this.pageSize);
  }

  get totalPages(): number {
    return Math.max(1, Math.ceil(this.transactions.length / this.pageSize));
  }

  goToPage(p: number): void {
    if (p < 1 || p > this.totalPages) return;
    this.page = p;
  }

  exportCsv(): void {
    const accountId = this.filters.accountId === "all" ? undefined : this.filters.accountId as number;
    this.transactionService.exportCsv({
      dateFrom: this.filters.dateFrom,
      dateTo: this.filters.dateTo,
      type: this.filters.type,
      accountId,
      contact: this.filters.contact,
      company: this.filters.company,
      category: this.filters.category,
      staff: this.filters.staff,
      paymentMethod: this.filters.paymentMethod
    }).subscribe({
      next: (blob) => {
        const url = window.URL.createObjectURL(blob);
        const a = document.createElement("a");
        a.href = url;
        a.download = "transactions_export.csv";
        a.click();
        window.URL.revokeObjectURL(url);
      },
      error: () => alert("Failed to export transactions.")
    });
  }
}
