import { Component, OnInit, ChangeDetectorRef } from "@angular/core";
import { CommonModule } from "@angular/common";
import { ActivatedRoute, Router } from "@angular/router";
import { InvoiceService, InvoiceDto, InvoiceItemDto } from "../../services/invoice.service";
import { CustomerService, CustomerDto } from "../../services/customer.service";

// Static issuer details — pull these from a company-settings API later if one gets built
const COMPANY = {
  name: "BizMotion Limited",
  addressLine1: "House: 995, Road: 9/A, Avenue: 11,",
  addressLine2: "Mirpur DOHS, Mirpur, Dhaka-1216",
  phone: "+880 1234 567890",
  email: "billing@bizmotion.com"
};

const BANK = {
  accountNumber: "1507 2033 1680 7001",
  accountName: "BIZ MOTION LIMITED",
  bankName: "BRAC Bank Limited",
  swift: "BBALBDDHXXX"
};

@Component({
  selector: "app-view-invoice",
  standalone: true,
  imports: [CommonModule],
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
  bank = BANK;

  statusOptions = ["Draft", "Unpaid", "Partially Paid", "Paid", "Cancelled"];

  constructor(
    private route: ActivatedRoute,
    private router: Router,
    private invoiceService: InvoiceService,
    private customerService: CustomerService,
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
    // TODO: build a real payment-recording flow once /api/payments exists
    alert("Add Payment is coming soon.");
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