import { Component, OnInit, ChangeDetectorRef } from "@angular/core";
import { CommonModule } from "@angular/common";
import { FormsModule } from "@angular/forms";
import { ActivatedRoute, Router } from "@angular/router";
import { InvoiceService, InvoiceDto, InvoiceItemDto } from "../../services/invoice.service";
import { CustomerService, CustomerDto } from "../../services/customer.service";
import { AccountService, AccountDto } from "../../services/account.service";
import { PaymentService, PaymentDto, CreatePaymentRequest } from "../../services/payment.service";

// Static issuer details — pull these from a company-settings API later if one gets built
const COMPANY = {
  name: "BizMotion Limited",
  addressLine1: "House: 995, Road: 9/A, Avenue: 11,",
  addressLine2: "Mirpur DOHS, Mirpur, Dhaka-1216",
  phone: "+880 1234 567890",
  email: "billing@bizmotion.com"
};

// Fallback bank details shown only until a payment has been recorded against
// a real Account — once a payment exists, the bank block below switches to
// that account's own details instead of this placeholder.
const BANK_FALLBACK = {
  accountNumber: "1507 2033 1680 7001",
  accountName: "BIZ MOTION LIMITED",
  bankName: "BRAC Bank Limited",
  swift: "BBALBDDHXXX"
};

@Component({
  selector: "app-view-invoice",
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: "./view-invoice.component.html",
  styleUrls: ["./view-invoice.component.css"]
})
export class ViewInvoiceComponent implements OnInit {

  loading = true;
  error   = "";
  updatingStatus = false;
  cloning = false;
  showStatusMenu = false;

  invoice: InvoiceDto | null = null;
  customer: CustomerDto | null = null;

  company = COMPANY;

  statusOptions = ["Draft", "Unpaid", "Partially Paid", "Paid", "Cancelled"];

  payments: PaymentDto[] = [];
  loadingPayments = false;

  showPaymentModal = false;
  savingPayment = false;
  paymentError = "";
  accounts: AccountDto[] = [];

  /** The account tied to the most recent payment on this invoice — once set,
   *  the "Bank" panel on the invoice shows this account's own details
   *  instead of the static BANK_FALLBACK placeholder. */
  paidToAccount: AccountDto | null = null;

  paymentForm = {
    accountId: null as number | null,
    date: new Date().toISOString().slice(0, 10),
    description: "",
    amount: null as number | null,
    currency: "BDT",
    category: "",
    payer: "",
    paymentMethod: "",
    referenceNo: "",
    notes: ""
  };

  constructor(
    private route: ActivatedRoute,
    private router: Router,
    private invoiceService: InvoiceService,
    private customerService: CustomerService,
    private accountService: AccountService,
    private paymentService: PaymentService,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    const id = Number(this.route.snapshot.paramMap.get("id"));
    if (!id) {
      this.error = "Invalid invoice id.";
      this.loading = false;
      this.cdr.detectChanges();
      return;
    }
    this.load(id);
  }

  private load(id: number): void {
    this.loading = true;
    this.error = "";
    this.invoiceService.getById(id).subscribe({
      next: (inv) => {
        this.invoice = inv;
        this.loading = false;
        this.cdr.detectChanges();

        this.customerService.getById(inv.customerId).subscribe({
          next: (c) => { this.customer = c; this.cdr.detectChanges(); },
          error: () => {} // non-fatal — invoice still renders with billingAddress only
        });

        this.loadPayments(id);
      },
      error: (err) => {
        this.loading = false;
        this.error = err.status === 404
          ? "Invoice not found."
          : (err?.error?.error || "Failed to load invoice.");
        this.cdr.detectChanges();
      }
    });
  }

  loadPayments(invoiceId: number): void {
    this.loadingPayments = true;
    this.paymentService.getForInvoice(invoiceId).subscribe({
      next: (data) => {
        this.payments = data;
        this.loadingPayments = false;
        this.cdr.detectChanges();
        this.resolvePaidToAccount();
      },
      error: () => { this.loadingPayments = false; this.cdr.detectChanges(); }
    });
  }

  /** Looks up the Account used for the most recent payment so the "Bank"
   *  panel can display real account details instead of the static fallback.
   *  Assumes PaymentDto exposes accountId; if payments are already sorted
   *  newest-first by the API, payments[0] is the most recent one. */
  private resolvePaidToAccount(): void {
    if (!this.payments || this.payments.length === 0) {
      this.paidToAccount = null;
      return;
    }
    const latest = this.payments[0];
    if (!latest.accountId) {
      this.paidToAccount = null;
      return;
    }

    const cached = this.accounts.find(a => a.id === latest.accountId);
    if (cached) {
      this.paidToAccount = cached;
      this.cdr.detectChanges();
      return;
    }

    this.accountService.getById(latest.accountId).subscribe({
      next: (acc) => { this.paidToAccount = acc; this.cdr.detectChanges(); },
      error: () => { this.paidToAccount = null; } // non-fatal — falls back to BANK_FALLBACK
    });
  }

  /** Bank details shown on the invoice. Once a payment has been recorded,
   *  this reflects the real account it was paid into; until then it shows
   *  the static placeholder. Swift/branch codes aren't part of AccountDto,
   *  so those fields still fall back to the placeholder value. */
  get bank(): { accountNumber: string; accountName: string; bankName: string; swift: string } {
    if (!this.paidToAccount) return BANK_FALLBACK;
    return {
      accountNumber: this.paidToAccount.accountNumber || BANK_FALLBACK.accountNumber,
      accountName: this.company.name,
      bankName: this.paidToAccount.accountTitle || BANK_FALLBACK.bankName,
      swift: BANK_FALLBACK.swift
    };
  }

  // ---- derived display helpers ----

  get billingMonth(): string {
    if (!this.invoice?.invoiceDate) return "";
    const d = new Date(this.invoice.invoiceDate);
    return d.toLocaleDateString("en-US", { month: "long" }) + ", " + d.toLocaleDateString("en-US", { year: "2-digit" });
  }

  get isOverdue(): boolean {
    if (!this.invoice?.dueDate || this.invoice.status === "Paid" || this.invoice.status === "Cancelled") return false;
    return this.invoice.dueDate < new Date().toISOString().slice(0, 10);
  }

  get grandTotalInWords(): string {
    if (!this.invoice) return "";
    return numberToWords(Math.round(this.invoice.grandTotal)) + " Taka only.";
  }

  statusPillClass(): string {
    switch (this.invoice?.status) {
      case "Paid":           return "pill-paid";
      case "Partially Paid": return "pill-partial";
      case "Cancelled":      return "pill-cancelled";
      case "Draft":          return "pill-draft";
      default:                return "pill-unpaid";
    }
  }

  // ---- actions ----

  toggleStatusMenu(): void {
    this.showStatusMenu = !this.showStatusMenu;
  }

  markAs(status: string): void {
    if (!this.invoice) return;
    this.showStatusMenu = false;
    this.updatingStatus = true;
    this.invoiceService.setStatus(this.invoice.id, status).subscribe({
      next: () => {
        this.updatingStatus = false;
        if (this.invoice) this.invoice.status = status;
        this.cdr.detectChanges();
      },
      error: (err) => {
        this.updatingStatus = false;
        this.cdr.detectChanges();
        alert(err?.error?.error || "Failed to update status.");
      }
    });
  }

  addPayment(): void {
    if (!this.invoice) return;
    this.paymentError = "";
    this.paymentForm = {
      accountId: null,
      date: new Date().toISOString().slice(0, 10),
      description: `Invoice Payment - ${this.invoice.invoiceNumber}`,
      amount: null,
      currency: this.invoice.currency,
      category: "",
      payer: this.invoice.customerName,
      paymentMethod: "",
      referenceNo: "",
      notes: ""
    };

    if (this.accounts.length === 0) {
      this.accountService.getAll().subscribe({
        next: (data) => {
          this.accounts = data.filter(a => a.status === "Active");
          this.cdr.detectChanges();
        },
        error: () => {}
      });
    }

    this.showPaymentModal = true;
  }

  closePaymentModal(): void {
    if (this.savingPayment) return;
    this.showPaymentModal = false;
  }

  savePayment(): void {
    if (!this.invoice) return;
    this.paymentError = "";

    if (!this.paymentForm.accountId) { this.paymentError = "Please choose an account."; return; }
    if (!this.paymentForm.amount || this.paymentForm.amount <= 0) { this.paymentError = "Payment amount cannot be zero."; return; }
    if (this.paymentForm.amount > this.invoice.remainingBalance) {
      this.paymentError = `Amount exceeds remaining balance of ${this.invoice.remainingBalance.toFixed(2)}.`;
      return;
    }

    const payload: CreatePaymentRequest = {
      accountId: this.paymentForm.accountId,
      date: this.paymentForm.date,
      amount: this.paymentForm.amount,
      currency: this.paymentForm.currency,
      category: this.paymentForm.category,
      payer: this.paymentForm.payer,
      paymentMethod: this.paymentForm.paymentMethod,
      referenceNo: this.paymentForm.referenceNo,
      description: this.paymentForm.description,
      notes: this.paymentForm.notes
    };

    this.savingPayment = true;
    this.paymentService.create(this.invoice.id, payload).subscribe({
      next: () => {
        this.savingPayment = false;
        this.showPaymentModal = false;
        this.load(this.invoice!.id); // refreshes invoice totals/status + payment history + bank panel together
        alert("Payment recorded successfully.");
      },
      error: (err) => {
        this.savingPayment = false;
        this.paymentError = err?.error?.error || err?.error?.message || "Failed to save payment.";
        this.cdr.detectChanges();
      }
    });
  }

  editInvoice(): void {
    if (!this.invoice) return;
    this.router.navigate(["/sales/edit-invoice", this.invoice.id]);
  }

  cloneInvoice(): void {
    if (!this.invoice) return;
    const confirmed = confirm(
      "Create a duplicate of this invoice? A new invoice with a new invoice number will be created, and you will be redirected to edit it."
    );
    if (!confirmed) return;

    this.cloning = true;
    this.invoiceService.clone(this.invoice.id).subscribe({
      next: (newInv) => {
        this.cloning = false;
        this.cdr.detectChanges();
        alert("Invoice cloned successfully. You are now editing the new invoice.");
        this.router.navigate(["/sales/edit-invoice", newInv.id]);
      },
      error: (err) => {
        this.cloning = false;
        this.cdr.detectChanges();
        alert(err?.error?.error || "Failed to clone invoice.");
      }
    });
  }

  downloadPdf(): void {
    if (!this.invoice) return;
    window.open(`/invoice-pdf/${this.invoice.id}`, "_blank");
  }

  excelView(): void {
    alert("Excel export is coming soon.");
  }

  print(): void {
    window.print();
  }

  backToList(): void {
    this.router.navigate(["/sales/invoices"]);
  }
}

/** Simple English number-to-words converter, good up to billions. */
function numberToWords(n: number): string {
  if (n === 0) return "Zero";
  const ones = ["", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine",
    "Ten", "Eleven", "Twelve", "Thirteen", "Fourteen", "Fifteen", "Sixteen", "Seventeen", "Eighteen", "Nineteen"];
  const tens = ["", "", "Twenty", "Thirty", "Forty", "Fifty", "Sixty", "Seventy", "Eighty", "Ninety"];

  function chunk(num: number): string {
    let str = "";
    if (num >= 100) {
      str += ones[Math.floor(num / 100)] + " Hundred ";
      num %= 100;
    }
    if (num >= 20) {
      str += tens[Math.floor(num / 10)] + " ";
      num %= 10;
    }
    if (num > 0) {
      str += ones[num] + " ";
    }
    return str.trim();
  }

  const scales = [
    { value: 1_000_000_000, label: "Billion" },
    { value: 1_000_000, label: "Million" },
    { value: 1_000, label: "Thousand" }
  ];

  let result = "";
  let remainder = n;
  for (const scale of scales) {
    if (remainder >= scale.value) {
      const count = Math.floor(remainder / scale.value);
      result += chunk(count) + " " + scale.label + " ";
      remainder %= scale.value;
    }
  }
  if (remainder > 0) result += chunk(remainder);

  return result.trim().replace(/\s+/g, " ");
}