import { Injectable } from "@angular/core";
import { HttpClient, HttpParams } from "@angular/common/http";
import { Observable } from "rxjs";

export interface TransactionDto {
  transactionId: string;
  date: string;
  accountId: number;
  accountTitle: string;
  company: string;
  contact: string;
  category: string;
  type: string;
  description: string;
  debit: number;
  credit: number;
  paymentMethod: string;
  staff: string;
  currency: string;
}

export interface TransactionFilters {
  dateFrom?: string;
  dateTo?: string;
  type?: string;
  accountId?: number;
  contact?: string;
  company?: string;
  category?: string;
  staff?: string;
  paymentMethod?: string;
}

export interface TransactionLookups {
  types: string[];
  contacts: string[];
  companies: string[];
  categories: string[];
  staff: string[];
  paymentMethods: string[];
}

@Injectable({ providedIn: "root" })
export class TransactionService {

  private api = "http://localhost:8080/api/transactions";

  constructor(private http: HttpClient) {}

  private buildParams(f: TransactionFilters): HttpParams {
    let params = new HttpParams();
    Object.entries(f).forEach(([key, val]) => {
      if (val !== null && val !== undefined && val !== "" && val !== "all") {
        params = params.set(key, String(val));
      }
    });
    return params;
  }

  getAll(filters: TransactionFilters): Observable<TransactionDto[]> {
    return this.http.get<TransactionDto[]>(this.api, { params: this.buildParams(filters) });
  }

  getLookups(): Observable<TransactionLookups> {
    return this.http.get<TransactionLookups>(`${this.api}/lookups`);
  }

  exportCsv(filters: TransactionFilters): Observable<Blob> {
    return this.http.get(`${this.api}/export.csv`, { params: this.buildParams(filters), responseType: "blob" });
  }
}
