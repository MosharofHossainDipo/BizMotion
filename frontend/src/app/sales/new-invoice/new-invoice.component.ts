import { Component, OnInit, ChangeDetectorRef } from "@angular/core";
import { CommonModule } from "@angular/common";
import { FormsModule } from "@angular/forms";
import { Router, ActivatedRoute } from "@angular/router";
import { CustomerService, CustomerDto } from "../../services/customer.service";
import { InvoiceService, CreateInvoiceItemRequest, CreateInvoiceRequest } from "../../services/invoice.service";

interface LineItem {
  id: number;
  description: string;
  qty: number;
  price: number;
}

interface InvoiceHeader {
  customerId: number | null;
  subject: string;
  address: string;
  status: "Draft" | "Published" | "Paid";
  currency: "BDT" | "USD" | "EUR";
  prefix: string;
  number: string;
  date: string;
  paymentTerms: string;
  taxPercent: number;
}

@Component({
  selector: "app-new-invoice",
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: "./new-invoice.component.html",
  styleUrls: ["./new-invoice.component.css"]
})
export class NewInvoiceComponent implements OnInit {
  saving = false;
  serverError = "";

  editMode = false;
  editingInvoiceId: number | null = null;
  loadingInvoice = false;

  customers: CustomerDto[] = [];
  loadingCustomers = false;
  customersError = "";

  invoice: InvoiceHeader = {
    customerId: null,
    subject: "",
    address: "",
    status: "Published",
    currency: "BDT",
    prefix: "INV-",
    number: "",
    date: "",
    paymentTerms: "Due On Receipt",
    taxPercent: 0
  };

  notesToCustomer = "Thank you for your business!";
  internalRemarks = "";

  lineItems: LineItem[] = [
    { id: 1, description: "", qty: 1, price: 0 }
  ];
  private nextId = 2;

  constructor(
    private router: Router,
    private route: ActivatedRoute,
    private customerService: CustomerService,
    private invoiceService: InvoiceService,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    const idParam = this.route.snapshot.paramMap.get("id");
    if (idParam) {
      this.editMode = true;
      this.editingInvoiceId = Number(idParam);
      this.loadInvoiceForEdit(this.editingInvoiceId);
    } else {
      const today = new Date();
      this.invoice.date = today.toISOString().slice(0, 10);
      this.invoice.number = String(10000000 + Math.floor(Math.random() * 89999999));
    }
    this.loadCustomers();
  }

  private loadInvoiceForEdit(id: number): void {
    this.loadingInvoice = true;
    this.invoiceService.getById(id).subscribe({
      next: (inv) => {
        this.invoice.customerId = inv.customerId;
        this.invoice.subject = (inv as any).subject || "";
        this.invoice.address = inv.billingAddress || "";
        this.invoice.currency = inv.currency as any;
        this.invoice.number = inv.invoiceNumber;
        this.invoice.date = inv.invoiceDate;
        this.invoice.paymentTerms = inv.paymentTerms || "";
        this.invoice.taxPercent = inv.taxPercent;
        this.notesToCustomer = inv.notesToCustomer || "";
        this.internalRemarks = inv.internalRemarks || "";

        this.lineItems = inv.items.map((it, idx) => ({
          id: idx + 1,
          description: it.description,
          qty: it.qty,
          price: it.unitPrice
        }));
        this.nextId = this.lineItems.length + 1;

        this.loadingInvoice = false;
        this.cdr.detectChanges();
      },
      error: (err) => {
        this.loadingInvoice = false;
        this.serverError = err?.error?.error || "Failed to load invoice for editing.";
        this.cdr.detectChanges();
      }
    });
  }

  loadCustomers(): void {
    this.loadingCustomers = true;
    this.customersError = "";
    this.customerService.getAll().subscribe({
      next: (data) => {
        this.customers = data;
        this.loadingCustomers = false;
        this.cdr.detectChanges();
      },
      error: (err) => {
        this.customersError = err?.error?.error || "Failed to load customers.";
        this.loadingCustomers = false;
        this.cdr.detectChanges();
      }
    });
  }

  onCustomerChange(): void {
    const selected = this.customers.find(c => c.id === this.invoice.customerId);
    if (selected) {
      this.invoice.address = selected.address || "";
    }
    this.cdr.detectChanges();
  }

  // ---- per-line calculation (no discount, no per-line tax) ----
  lineTotal(item: LineItem): number {
    return item.qty * item.price;
  }

  // ---- invoice-wide totals ----
  get subtotal(): number {
    return this.lineItems.reduce((sum, item) => sum + this.lineTotal(item), 0);
  }

  get taxTotal(): number {
    return this.subtotal * (this.invoice.taxPercent / 100);
  }

  get grandTotal(): number {
    return this.subtotal + this.taxTotal;
  }

  // ---- actions ----
  addBlankLine(): void {
    this.lineItems.push({ id: this.nextId++, description: "", qty: 1, price: 0 });
  }

  addProductOrService(): void {
    // TODO: open a product/service catalog picker once that module exists
    this.addBlankLine();
  }

  removeItem(id: number): void {
    if (this.lineItems.length === 1) return;
    this.lineItems = this.lineItems.filter(i => i.id !== id);
  }

  addNewCustomer(): void {
    this.router.navigate(["/customers/add"]);
  }

  private buildPayload(): CreateInvoiceRequest | null {
    if (!this.invoice.customerId) {
      this.serverError = "Please select a customer.";
      return null;
    }
    if (!this.lineItems.length || this.lineItems.every(i => !i.description.trim())) {
      this.serverError = "Add at least one line item.";
      return null;
    }

    const items: CreateInvoiceItemRequest[] = this.lineItems.map(i => ({
      description: i.description,
      qty: i.qty,
      unitPrice: i.price
    }));

    return {
      customerId: this.invoice.customerId,
      subject: this.invoice.subject,
      billingAddress: this.invoice.address,
      invoiceType: "Onetime",
      currency: this.invoice.currency,
      prefix: this.invoice.prefix,
      paymentTerms: this.invoice.paymentTerms,
      taxPercent: this.invoice.taxPercent,
      invoiceDate: this.invoice.date,
      notesToCustomer: this.notesToCustomer,
      internalRemarks: this.internalRemarks,
      items
    };
  }

  saveDraft(): void {
    this.serverError = "";
    const payload = this.buildPayload();
    if (!payload) return;

    this.saving = true;
    const req$ = this.editMode && this.editingInvoiceId
      ? this.invoiceService.update(this.editingInvoiceId, payload)
      : this.invoiceService.create(payload, false);

    req$.subscribe({
      next: (inv) => {
        this.saving = false;
        alert(`Draft saved as ${inv.invoiceNumber}.`);
        this.router.navigate(["/sales/invoices"]);
      },
      error: (err) => {
        this.saving = false;
        this.serverError = this.describeError(err);
      }
    });
  }

  finalizeAndSend(): void {
    this.serverError = "";
    const payload = this.buildPayload();
    if (!payload) return;

    this.saving = true;

    if (this.editMode && this.editingInvoiceId) {
      this.invoiceService.update(this.editingInvoiceId, payload).subscribe({
        next: (inv) => {
          this.invoiceService.setStatus(inv.id, "Unpaid").subscribe({
            next: () => {
              this.saving = false;
              alert(`Invoice ${inv.invoiceNumber} finalized and sent.`);
              this.router.navigate(["/sales/invoices"]);
            },
            error: (err) => { this.saving = false; this.serverError = this.describeError(err); }
          });
        },
        error: (err) => { this.saving = false; this.serverError = this.describeError(err); }
      });
      return;
    }

    this.invoiceService.create(payload, true).subscribe({
      next: (inv) => {
        this.saving = false;
        alert(`Invoice ${inv.invoiceNumber} finalized and sent.`);
        this.router.navigate(["/sales/invoices"]);
      },
      error: (err) => {
        this.saving = false;
        this.serverError = this.describeError(err);
      }
    });
  }

  private describeError(err: any): string {
    if (err.status === 0)   return "Cannot connect to backend. Make sure the Spring Boot server is running on port 8080.";
    if (err.status === 403) return "You do not have permission to create invoices.";
    if (err.status === 401) return "Session expired. Please login again.";
    if (err.status === 404) return "Selected customer could not be found.";
    return err?.error?.error || err?.error?.message || `Error ${err.status}: Failed to save invoice.`;
  }
}