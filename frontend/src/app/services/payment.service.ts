import { Injectable } from "@angular/core";
import { HttpClient } from "@angular/common/http";
import { Observable } from "rxjs";

export interface PaymentDto {
  id: number;
  paymentCode: string;
  invoiceId: number;
  invoiceNumber: string;
  customerId: number;
  customerName: string;
  accountId: number;
  accountTitle: string;
  date: string;
  amount: number;
  currency: string;
  category: string;
  payer: string;
  paymentMethod: string;
  referenceNo: string;
  description: string;
  notes: string;
  createdAt: string;
}

export interface CreatePaymentRequest {
  accountId: number;
  date: string;
  amount: number;
  currency?: string;
  category?: string;
  payer?: string;
  paymentMethod?: string;
  referenceNo?: string;
  description?: string;
  notes?: string;
}

@Injectable({ providedIn: "root" })
export class PaymentService {

  private api = "http://localhost:8080/api/invoices";

  constructor(private http: HttpClient) {}

  getForInvoice(invoiceId: number): Observable<PaymentDto[]> {
    return this.http.get<PaymentDto[]>(`${this.api}/${invoiceId}/payments`);
  }

  create(invoiceId: number, req: CreatePaymentRequest): Observable<PaymentDto> {
    return this.http.post<PaymentDto>(`${this.api}/${invoiceId}/payments`, req);
  }
}
