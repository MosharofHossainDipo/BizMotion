import { Injectable } from "@angular/core";
import { HttpClient } from "@angular/common/http";
import { Observable } from "rxjs";

export interface DepositDto {
  id: number;
  depositCode: string;
  accountId: number;
  accountTitle: string;
  date: string;
  description: string;
  currency: string;
  amount: number;
  category: string;
  tags: string;
  company: string;
  payer: string;
  staff: string;
  paymentMethod: string;
  referenceNo: string;
  createdAt: string;
}

export interface CreateDepositRequest {
  accountId: number;
  date: string;
  description?: string;
  currency?: string;
  amount: number;
  category?: string;
  tags?: string;
  company?: string;
  payer?: string;
  staff?: string;
  paymentMethod?: string;
  referenceNo?: string;
}

export interface DepositLookups {
  categories: string[];
  companies: string[];
  payers: string[];
  staff: string[];
  paymentMethods: string[];
}

@Injectable({ providedIn: "root" })
export class DepositService {

  private api = "http://localhost:8080/api/deposits";

  constructor(private http: HttpClient) {}

  getAll(): Observable<DepositDto[]> {
    return this.http.get<DepositDto[]>(this.api);
  }

  getLookups(): Observable<DepositLookups> {
    return this.http.get<DepositLookups>(`${this.api}/lookups`);
  }

  create(req: CreateDepositRequest): Observable<DepositDto> {
    return this.http.post<DepositDto>(this.api, req);
  }
}
