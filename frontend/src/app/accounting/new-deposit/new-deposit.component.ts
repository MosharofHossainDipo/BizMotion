import { Component, OnInit, ChangeDetectorRef } from "@angular/core";
import { CommonModule } from "@angular/common";
import { FormsModule } from "@angular/forms";
import { AccountService, AccountDto } from "../../services/account.service";
import { CustomerService, CustomerDto } from "../../services/customer.service";
import { DepositService, DepositDto, DepositLookups, CreateDepositRequest } from "../../services/deposit.service";
import { ComboInputComponent } from "../../shared/combo-input/combo-input.component";

@Component({
  selector: "app-new-deposit",
  standalone: true,
  imports: [CommonModule, FormsModule, ComboInputComponent],
  templateUrl: "./new-deposit.component.html",
  styleUrls: ["./new-deposit.component.css"]
})
export class NewDepositComponent implements OnInit {

  accounts: AccountDto[] = [];
  loadingAccounts = false;

  customers: CustomerDto[] = [];

  lookups: DepositLookups = { categories: [], companies: [], payers: [], staff: [], paymentMethods: [] };

  deposits: DepositDto[] = [];
  loadingDeposits = true;
  listError = "";

  saving = false;
  serverError = "";

  form = {
    accountId: null as number | null,
    date: new Date().toISOString().slice(0, 10),
    description: "",
    currency: "BDT",
    amount: null as number | null,
    category: "",
    tags: "",
    company: "",
    payer: "",
    staff: "",
    paymentMethod: "",
    referenceNo: ""
  };

  get payerOptions(): string[] {
    return [...new Set(this.customers.map(c => c.name).filter(n => !!n && n.trim()))];
  }

  get companyOptions(): string[] {
    return [...new Set(this.customers.map(c => c.company).filter(c => !!c && c.trim()))];
  }

  constructor(
    private accountService: AccountService,
    private customerService: CustomerService,
    private depositService: DepositService,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    this.loadAccounts();
    this.loadCustomers();
    this.loadLookups();
    this.loadDeposits();
  }

  loadAccounts(): void {
    this.loadingAccounts = true;
    this.accountService.getAll().subscribe({
      next: (data) => {
        this.accounts = data.filter(a => a.status === "Active");
        this.loadingAccounts = false;
        this.cdr.detectChanges();
      },
      error: () => { this.loadingAccounts = false; this.cdr.detectChanges(); }
    });
  }

  loadCustomers(): void {
    this.customerService.getAll().subscribe({
      next: (data) => { this.customers = data; this.cdr.detectChanges(); },
      error: () => {} // non-fatal — Company/Payer combo boxes just stay empty-suggestion
    });
  }

  loadLookups(): void {
    this.depositService.getLookups().subscribe({
      next: (data) => { this.lookups = data; this.cdr.detectChanges(); },
      error: () => {} // non-fatal — datalists just stay empty
    });
  }

  loadDeposits(): void {
    this.loadingDeposits = true;
    this.listError = "";
    this.depositService.getAll().subscribe({
      next: (data) => {
        this.deposits = data;
        this.loadingDeposits = false;
        this.cdr.detectChanges();
      },
      error: (err) => {
        this.loadingDeposits = false;
        this.listError = err?.error?.error || "Failed to load recent deposits.";
        this.cdr.detectChanges();
      }
    });
  }

  save(): void {
    this.serverError = "";
    if (!this.form.accountId) { this.serverError = "Please choose an account."; return; }
    if (!this.form.amount || this.form.amount <= 0) { this.serverError = "Enter a valid amount greater than zero."; return; }

    const payload: CreateDepositRequest = {
      accountId: this.form.accountId,
      date: this.form.date,
      description: this.form.description,
      currency: this.form.currency,
      amount: this.form.amount,
      category: this.form.category,
      tags: this.form.tags,
      company: this.form.company,
      payer: this.form.payer,
      staff: this.form.staff,
      paymentMethod: this.form.paymentMethod,
      referenceNo: this.form.referenceNo
    };

    this.saving = true;
    this.depositService.create(payload).subscribe({
      next: () => {
        this.saving = false;
        this.resetForm();
        this.loadLookups();
        this.loadDeposits();
      },
      error: (err) => {
        this.saving = false;
        this.serverError = err?.error?.error || err?.error?.message || "Failed to record deposit.";
        this.cdr.detectChanges();
      }
    });
  }

  private resetForm(): void {
    this.form = {
      accountId: null,
      date: new Date().toISOString().slice(0, 10),
      description: "",
      currency: "BDT",
      amount: null,
      category: "",
      tags: "",
      company: "",
      payer: "",
      staff: "",
      paymentMethod: "",
      referenceNo: ""
    };
  }
}