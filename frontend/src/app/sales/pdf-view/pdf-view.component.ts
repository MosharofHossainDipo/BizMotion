import { Component, OnInit, ChangeDetectorRef } from "@angular/core";
import { CommonModule } from "@angular/common";
import { ActivatedRoute } from "@angular/router";
import { InvoiceService, InvoiceDto } from "../../services/invoice.service";
import { CustomerService, CustomerDto } from "../../services/customer.service";

// Static issuer details for the on-screen preview — the actual PDF's
// company/footer text lives in the backend's InvoicePdfService.java now.
const COMPANY = {
  name: "BIZMOTION LIMITED.",
  logoUrl: "/logo.png",
  footerAddress: "House no # 995, Road no# 9/A, Avenue 11, Mirpur DOHS, Dhaka-1216.",
  footerEmail: "contact@biz-motion.com",
  footerWeb: "www.biz-motion.com"
};

const CURRENCY_SYMBOLS: Record<string, string> = { BDT: "৳", USD: "$", EUR: "€" };

@Component({
  selector: "app-pdf-view",
  standalone: true,
  imports: [CommonModule],
  templateUrl: "./pdf-view.component.html",
  styleUrls: ["./pdf-view.component.css"]
})
export class PdfViewComponent implements OnInit {

  loading = true;
  error   = "";
  generating = false;

  invoice: InvoiceDto | null = null;
  customer: CustomerDto | null = null;

  company = COMPANY;

  /** Excludes the logo/tracking/footer from the generated PDF — for
   *  printing onto pre-printed company letterhead paper. */
  letterheadMode = false;

  /** Data-URL of an uploaded signature image, sent to the backend and
   *  embedded above the "Authorized Signature and Seal" line. */
  authorizedSignatureUrl: string | null = null;

  constructor(
    private route: ActivatedRoute,
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
          error: () => {}
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

  // ---- display helpers (on-screen HTML preview only) ----

  get currencySymbol(): string {
    if (!this.invoice) return "";
    return CURRENCY_SYMBOLS[this.invoice.currency] || (this.invoice.currency + " ");
  }

  formatMoney(value: number): string {
    return this.currencySymbol + (value ?? 0).toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 });
  }

  formatDate(dateStr: string | null | undefined): string {
    if (!dateStr) return "—";
    const d = new Date(dateStr);
    const dd = String(d.getDate()).padStart(2, "0");
    const mm = String(d.getMonth() + 1).padStart(2, "0");
    const yyyy = d.getFullYear();
    return `${dd}/${mm}/${yyyy}`;
  }

  get billToAddress(): string {
    return this.invoice?.billingAddress || this.customer?.address || "";
  }

  get statusLower(): string {
    return (this.invoice?.status || "").toLowerCase().replace(/\s+/g, "-");
  }

  /** Leftover from an earlier CSS-based pagination experiment — the on-
   *  screen preview no longer needs to simulate page breaks since the
   *  real PDF is generated server-side now. Kept as a harmless 0 so any
   *  remaining template reference doesn't break the build; safe to
   *  delete the binding from the .html entirely when convenient. */
  get spacerHeightPx(): number {
    return 0;
  }

  // ---- digital signature ----

  onSignatureFileSelected(event: Event): void {
    const input = event.target as HTMLInputElement;
    const file = input.files && input.files[0];
    if (!file) return;

    if (!file.type.startsWith("image/")) {
      alert("Please choose an image file (PNG or JPG) for the signature.");
      return;
    }

    const reader = new FileReader();
    reader.onload = () => {
      this.authorizedSignatureUrl = reader.result as string;
      this.cdr.detectChanges();
    };
    reader.readAsDataURL(file);

    input.value = "";
  }

  removeSignature(): void {
    this.authorizedSignatureUrl = null;
  }

  // ---- PDF actions — server-generated (iText), real page control ----

  downloadPdf(): void {
    this.requestPdf(false, (blob) => {
      const url = URL.createObjectURL(blob);
      const a = document.createElement("a");
      a.href = url;
      a.download = `${this.invoice!.invoiceNumber}.pdf`;
      a.click();
      URL.revokeObjectURL(url);
    });
  }

  printPdf(): void {
    this.requestPdf(false, (blob) => this.openBlobInNewTab(blob));
  }

  printLetterhead(): void {
    this.requestPdf(true, (blob) => this.openBlobInNewTab(blob));
  }

  private requestPdf(letterhead: boolean, onSuccess: (blob: Blob) => void): void {
    if (!this.invoice) return;
    this.generating = true;
    this.cdr.detectChanges();

    this.invoiceService.getPdf(this.invoice.id, letterhead, this.authorizedSignatureUrl).subscribe({
      next: (blob) => {
        this.generating = false;
        this.cdr.detectChanges();
        onSuccess(blob);
      },
      error: (err) => {
        this.generating = false;
        this.cdr.detectChanges();
        alert(err?.error?.error || "Failed to generate PDF. Please try again.");
      }
    });
  }

  /** Opens the PDF in a new tab using the browser's built-in PDF viewer,
   *  which has its own Print button — reliable across browsers. */
  private openBlobInNewTab(blob: Blob): void {
    const url = URL.createObjectURL(blob);
    window.open(url, "_blank");
    // revoke later — the new tab needs time to actually load the blob URL
    setTimeout(() => URL.revokeObjectURL(url), 60000);
  }
}