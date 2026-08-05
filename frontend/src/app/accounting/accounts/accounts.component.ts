import { Component, OnInit, ChangeDetectorRef } from "@angular/core";
import { CommonModule } from "@angular/common";
import { FormsModule } from "@angular/forms";
import { Router } from "@angular/router";
import { AccountService, AccountDto } from "../../services/account.service";

@Component({
  selector: "app-accounts",
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: "./accounts.component.html",
  styleUrls: ["./accounts.component.css"]
})
export class AccountsComponent implements OnInit {

  search = "";
  accounts: AccountDto[] = [];
  loading = true;
  error = "";
  deletingId: number | null = null;

  showBalanceModal = false;
  balanceTarget: AccountDto | null = null;
  balanceBdt = 0;
  balanceUsd = 0;
  savingBalance = false;

  get filtered(): AccountDto[] {
    if (!this.search.trim()) return this.accounts;
    const s = this.search.toLowerCase();
    return this.accounts.filter(a =>
      a.accountTitle.toLowerCase().includes(s) ||
      (a.accountCode || "").toLowerCase().includes(s)
    );
  }

  get totalAccounts(): number { return this.accounts.length; }
  get grandTotalBalance(): number {
    return this.accounts.reduce((sum, a) => sum + (a.currentBalance || 0), 0);
  }

  constructor(
    private router: Router,
    private accountService: AccountService,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    this.load();
  }

  load(): void {
    this.loading = true;
    this.error = "";
    this.accountService.getAll().subscribe({
      next: (data) => {
        this.accounts = data.filter(a => a.status !== "Deleted");
        this.loading = false;
        this.cdr.detectChanges();
      },
      error: (err) => {
        this.loading = false;
        this.error = err.status === 0
          ? "Cannot connect to backend on port 8080."
          : (err?.error?.error || "Failed to load accounts.");
        this.cdr.detectChanges();
      }
    });
  }

  addNew(): void {
    this.router.navigate(["/accounting/new-account"]);
  }

  openBalanceModal(acc: AccountDto): void {
    this.balanceTarget = acc;
    this.balanceBdt = acc.initialBalanceBdt;
    this.balanceUsd = acc.initialBalanceUsd;
    this.showBalanceModal = true;
  }

  closeBalanceModal(): void {
    if (this.savingBalance) return;
    this.showBalanceModal = false;
    this.balanceTarget = null;
  }

  saveBalance(): void {
    if (!this.balanceTarget) return;
    this.savingBalance = true;
    this.accountService.recordInitialBalance(this.balanceTarget.id, this.balanceBdt, this.balanceUsd).subscribe({
      next: (updated) => {
        const idx = this.accounts.findIndex(a => a.id === updated.id);
        if (idx > -1) this.accounts[idx] = updated;
        this.savingBalance = false;
        this.showBalanceModal = false;
        this.balanceTarget = null;
        this.cdr.detectChanges();
      },
      error: (err) => {
        this.savingBalance = false;
        alert(err?.error?.error || "Failed to update initial balance.");
        this.cdr.detectChanges();
      }
    });
  }

  delete(acc: AccountDto): void {
    if (!confirm(`Delete "${acc.accountTitle}"? This can't be undone from the UI.`)) return;
    this.deletingId = acc.id;
    this.accountService.delete(acc.id).subscribe({
      next: () => {
        this.accounts = this.accounts.filter(a => a.id !== acc.id);
        this.deletingId = null;
        this.cdr.detectChanges();
      },
      error: (err) => {
        this.deletingId = null;
        alert(err?.error?.error || "Failed to delete account.");
        this.cdr.detectChanges();
      }
    });
  }
}
