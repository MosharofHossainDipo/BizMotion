import { Injectable } from "@angular/core";
import { HttpClient } from "@angular/common/http";
import { Observable } from "rxjs";

export interface TransferDto {
  id: number;
  transferCode: string;
  fromAccountId: number;
  fromAccountTitle: string;
  toAccountId: number;
  toAccountTitle: string;
  date: string;
  description: string;
  currency: string;
  amount: number;
  tags: string;
  paymentMethod: string;
  referenceNo: string;
  createdAt: string;
}

export interface CreateTransferRequest {
  fromAccountId: number;
  toAccountId: number;
  date: string;
  description?: string;
  currency?: string;
  amount: number;
  tags?: string;
  paymentMethod?: string;
  referenceNo?: string;
}

@Injectable({ providedIn: "root" })
export class TransferService {

  private api = "http://localhost:8080/api/transfers";

  constructor(private http: HttpClient) {}

  getAll(): Observable<TransferDto[]> {
    return this.http.get<TransferDto[]>(this.api);
  }

  getPaymentMethods(): Observable<string[]> {
    return this.http.get<string[]>(`${this.api}/payment-methods`);
  }

  create(req: CreateTransferRequest): Observable<TransferDto> {
    return this.http.post<TransferDto>(this.api, req);
  }
}
