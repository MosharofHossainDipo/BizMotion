import { Component, OnInit, ChangeDetectorRef } from "@angular/core";
import { CommonModule } from "@angular/common";
import { FormsModule } from "@angular/forms";
import { AccountService, AccountDto } from "../../services/account.service";
import { TransferService, TransferDto, CreateTransferRequest } from "../../services/transfer.service";
import { ComboInputComponent } from "../../shared/combo-input/combo-input.component";

@Component({
  selector: "app-transfer",
  standalone: true,
  imports: [CommonModule, FormsModule, ComboInputComponent],
  templateUrl: "./transfer.component.html",
  styleUrls: ["./transfer.component.css"]
})
export class TransferComponent implements OnInit {

  accounts: AccountDto[] = [];
  loadingAccounts = false;

  paymentMethods: string[] = [];

  transfers: TransferDto[] = [];
  loadingTransfers = true;
  listError = "";

  saving = false;
  serverError = "";

  form = {
    fromAccountId: null as number | null,
    toAccountId: null as number | null,
    date: new Date().toISOString().slice(0, 10),
    description: "",
    currency: "BDT",
    amount: null as number | null,
    tags: "",
    paymentMethod: "",
    referenceNo: ""
  };

  constructor(
    private accountService: AccountService,
    private transferService: TransferService,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    this.loadAccounts();
    this.loadPaymentMethods();
    this.loadTransfers();
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

  loadPaymentMethods(): void {
    this.transferService.getPaymentMethods().subscribe({
      next: (data) => { this.paymentMethods = data; this.cdr.detectChanges(); },
      error: () => {}
    });
  }

  loadTransfers(): void {
    this.loadingTransfers = true;
    this.listError = "";
    this.transferService.getAll().subscribe({
      next: (data) => {
        this.transfers = data;
        this.loadingTransfers = false;
        this.cdr.detectChanges();
      },
      error: (err) => {
        this.loadingTransfers = false;
        this.listError = err?.error?.error || "Failed to load recent transfers.";
        this.cdr.detectChanges();
      }
    });
  }

  save(): void {
    this.serverError = "";
    if (!this.form.fromAccountId) { this.serverError = "Please choose a source account."; return; }
    if (!this.form.toAccountId) { this.serverError = "Please choose a destination account."; return; }
    if (this.form.fromAccountId === this.form.toAccountId) { this.serverError = "Source and destination account must be different."; return; }
    if (!this.form.amount || this.form.amount <= 0) { this.serverError = "Enter a valid amount greater than zero."; return; }

    const payload: CreateTransferRequest = {
      fromAccountId: this.form.fromAccountId,
      toAccountId: this.form.toAccountId,
      date: this.form.date,
      description: this.form.description,
      currency: this.form.currency,
      amount: this.form.amount,
      tags: this.form.tags,
      paymentMethod: this.form.paymentMethod,
      referenceNo: this.form.referenceNo
    };

    this.saving = true;
    this.transferService.create(payload).subscribe({
      next: () => {
        this.saving = false;
        this.resetForm();
        this.loadPaymentMethods();
        this.loadTransfers();
      },
      error: (err) => {
        this.saving = false;
        this.serverError = err?.error?.error || err?.error?.message || "Failed to record transfer.";
        this.cdr.detectChanges();
      }
    });
  }

  private resetForm(): void {
    this.form = {
      fromAccountId: null,
      toAccountId: null,
      date: new Date().toISOString().slice(0, 10),
      description: "",
      currency: "BDT",
      amount: null,
      tags: "",
      paymentMethod: "",
      referenceNo: ""
    };
  }
}
