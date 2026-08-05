import { Component, OnInit, ChangeDetectorRef } from "@angular/core";
import { CommonModule } from "@angular/common";
import { FormsModule } from "@angular/forms";
import { AccountService, AccountDto } from "../../services/account.service";
import { CustomerService, CustomerDto } from "../../services/customer.service";
import { ExpenseService, ExpenseDto, ExpenseLookups, CreateExpenseRequest } from "../../services/expense.service";
import { ComboInputComponent } from "../../shared/combo-input/combo-input.component";

@Component({
  selector: "app-new-expense",
  standalone: true,
  imports: [CommonModule, FormsModule, ComboInputComponent],
  templateUrl: "./new-expense.component.html",
  styleUrls: ["./new-expense.component.css"]
})
export class NewExpenseComponent implements OnInit {

  accounts: AccountDto[] = [];
  loadingAccounts = false;

  customers: CustomerDto[] = [];

  lookups: ExpenseLookups = { categories: [], staff: [], paymentMethods: [] };

  expenses: ExpenseDto[] = [];
  loadingExpenses = true;
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
    payee: "",
    staff: "",
    paymentMethod: "",
    status: "Cleared",
    referenceNo: ""
  };

  get payeeOptions(): string[] {
    return [...new Set(this.customers.map(c => c.name).filter(n => !!n && n.trim()))];
  }

  get companyOptions(): string[] {
    return [...new Set(this.customers.map(c => c.company).filter(c => !!c && c.trim()))];
  }

  constructor(
    private accountService: AccountService,
    private customerService: CustomerService,
    private expenseService: ExpenseService,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    this.loadAccounts();
    this.loadCustomers();
    this.loadLookups();
    this.loadExpenses();
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
      error: () => {}
    });
  }

  loadLookups(): void {
    this.expenseService.getLookups().subscribe({
      next: (data) => { this.lookups = data; this.cdr.detectChanges(); },
      error: () => {}
    });
  }

  loadExpenses(): void {
    this.loadingExpenses = true;
    this.listError = "";
    this.expenseService.getAll().subscribe({
      next: (data) => {
        this.expenses = data;
        this.loadingExpenses = false;
        this.cdr.detectChanges();
      },
      error: (err) => {
        this.loadingExpenses = false;
        this.listError = err?.error?.error || "Failed to load recent expenses.";
        this.cdr.detectChanges();
      }
    });
  }

  save(): void {
    this.serverError = "";
    if (!this.form.accountId) { this.serverError = "Please choose an account."; return; }
    if (!this.form.amount || this.form.amount <= 0) { this.serverError = "Enter a valid amount greater than zero."; return; }

    const payload: CreateExpenseRequest = {
      accountId: this.form.accountId,
      date: this.form.date,
      description: this.form.description,
      currency: this.form.currency,
      amount: this.form.amount,
      category: this.form.category,
      tags: this.form.tags,
      company: this.form.company,
      payee: this.form.payee,
      staff: this.form.staff,
      paymentMethod: this.form.paymentMethod,
      status: this.form.status,
      referenceNo: this.form.referenceNo
    };

    this.saving = true;
    this.expenseService.create(payload).subscribe({
      next: () => {
        this.saving = false;
        this.resetForm();
        this.loadLookups();
        this.loadExpenses();
      },
      error: (err) => {
        this.saving = false;
        this.serverError = err?.error?.error || err?.error?.message || "Failed to record expense.";
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
      payee: "",
      staff: "",
      paymentMethod: "",
      status: "Cleared",
      referenceNo: ""
    };
  }
}
