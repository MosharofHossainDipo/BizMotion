import { Component } from "@angular/core";
import { CommonModule } from "@angular/common";
import { FormsModule } from "@angular/forms";
import { Router } from "@angular/router";
import { AccountService, CreateAccountRequest } from "../../services/account.service";

@Component({
  selector: "app-new-account",
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: "./new-account.component.html",
  styleUrls: ["./new-account.component.css"]
})
export class NewAccountComponent {
  saving = false;
  serverError = "";

  form = {
    accountTitle: "",
    description: "",
    initialBalanceUsd: 0,
    initialBalanceBdt: 0,
    accountNumber: "",
    internetBankingUrl: "",
    contactPerson: "",
    phone: ""
  };

  constructor(private router: Router, private accountService: AccountService) {}

  discard(): void {
    this.router.navigate(["/accounting/accounts"]);
  }

  save(): void {
    this.serverError = "";
    if (!this.form.accountTitle.trim()) {
      this.serverError = "Account title is required.";
      return;
    }

    const payload: CreateAccountRequest = {
      accountTitle: this.form.accountTitle,
      description: this.form.description,
      accountNumber: this.form.accountNumber,
      contactPerson: this.form.contactPerson,
      phone: this.form.phone,
      internetBankingUrl: this.form.internetBankingUrl,
      initialBalanceBdt: this.form.initialBalanceBdt,
      initialBalanceUsd: this.form.initialBalanceUsd
    };

    this.saving = true;
    this.accountService.create(payload).subscribe({
      next: () => {
        this.saving = false;
        this.router.navigate(["/accounting/accounts"]);
      },
      error: (err) => {
        this.saving = false;
        this.serverError = err?.error?.error || err?.error?.message || "Failed to create account.";
      }
    });
  }
}
