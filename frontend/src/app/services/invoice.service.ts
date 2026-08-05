import { Injectable } from "@angular/core";
import { HttpClient, HttpParams } from "@angular/common/http";
import { Observable } from "rxjs";

export interface InvoiceItemDto {
  id: number;
  description: string;
  qty: number;
  unitPrice: number;
  lineTotal: number;
  sortOrder: number;
}

export interface InvoiceDto {
  id: number;
  invoiceNumber: string;
  trackingNumber: string;
  subject: string;
  customerId: number;
  customerName: string;
  billingAddress: string;
  status: string;
  invoiceType: string;
  currency: string;
  paymentTerms: string;
  invoiceDate: string;
  dueDate: string;
  taxPercent: number;
  subtotal: number;
  taxTotal: number;
  grandTotal: number;
  notesToCustomer: string;
  internalRemarks: string;
  createdAt: string;
  updatedAt: string;
  items: InvoiceItemDto[];
}

export interface CreateInvoiceItemRequest {
  description: string;
  qty: number;
  unitPrice: number;
}

export interface CreateInvoiceRequest {
  customerId: number;
  subject?: string;
  billingAddress?: string;
  invoiceType?: string;
  currency?: string;
  prefix?: string;
  paymentTerms?: string;
  taxPercent?: number;
  invoiceDate: string;   // yyyy-MM-dd
  dueDate?: string;      // yyyy-MM-dd
  notesToCustomer?: string;
  internalRemarks?: string;
  items: CreateInvoiceItemRequest[];
}

export interface InvoiceImportResult {
  totalInvoices: number;
  imported:      number;
  duplicates:    number;
  invalid:       number;
  errors:        string[];
}

@Injectable({ providedIn: "root" })
export class InvoiceService {

  private api = "http://localhost:8080/api/invoices";

  // No manual headers — JWT interceptor handles Authorization automatically

  constructor(private http: HttpClient) {}

  getAll(): Observable<InvoiceDto[]> {
    return this.http.get<InvoiceDto[]>(this.api);
  }

  getById(id: number): Observable<InvoiceDto> {
    return this.http.get<InvoiceDto>(`${this.api}/${id}`);
  }

  create(req: CreateInvoiceRequest, finalize: boolean): Observable<InvoiceDto> {
    const params = new HttpParams().set("finalize", String(finalize));
    return this.http.post<InvoiceDto>(this.api, req, { params });
  }

  update(id: number, req: Partial<CreateInvoiceRequest>): Observable<InvoiceDto> {
    return this.http.put<InvoiceDto>(`${this.api}/${id}`, req);
  }

  setStatus(id: number, status: string): Observable<string> {
    return this.http.put(`${this.api}/${id}/status`, { status }, { responseType: "text" });
  }

  delete(id: number): Observable<string> {
    return this.http.delete(`${this.api}/${id}`, { responseType: "text" });
  }

  /** Calls the server-side (iText) PDF generation endpoint — reliable
   *  page breaks, repeating header/footer, unbreakable totals/signature
   *  blocks, all computed in Java, not the browser. */
  getPdf(id: number, letterhead: boolean, signatureImageBase64: string | null): Observable<Blob> {
    return this.http.post(
      `${this.api}/${id}/pdf`,
      { letterhead, signatureImageBase64 },
      { responseType: "blob" }
    );
  }

  /** Duplicates an existing invoice into a brand-new Draft invoice —
   *  matches POST /api/invoices/{id}/clone on the backend. */
  clone(id: number): Observable<InvoiceDto> {
    return this.http.post<InvoiceDto>(`${this.api}/${id}/clone`, {});
  }

  importInvoices(file: File): Observable<InvoiceImportResult> {
    const formData = new FormData();
    formData.append("file", file);
    return this.http.post<InvoiceImportResult>(`${this.api}/import`, formData);
  }

  downloadTemplate(): Observable<Blob> {
    return this.http.get(`${this.api}/import/template`, { responseType: "blob" });
  }
}