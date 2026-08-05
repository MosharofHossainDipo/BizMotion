import { Injectable } from "@angular/core";
import { HttpClient } from "@angular/common/http";
import { Observable } from "rxjs";

export interface ExpenseDto {
  id: number;
  expenseCode: string;
  accountId: number;
  accountTitle: string;
  date: string;
  description: string;
  currency: string;
  amount: number;
  category: string;
  tags: string;
  company: string;
  payee: string;
  staff: string;
  paymentMethod: string;
  status: string;
  referenceNo: string;
  createdAt: string;
}

export interface CreateExpenseRequest {
  accountId: number;
  date: string;
  description?: string;
  currency?: string;
  amount: number;
  category?: string;
  tags?: string;
  company?: string;
  payee?: string;
  staff?: string;
  paymentMethod?: string;
  status?: string;
  referenceNo?: string;
}

export interface ExpenseLookups {
  categories: string[];
  staff: string[];
  paymentMethods: string[];
}

@Injectable({ providedIn: "root" })
export class ExpenseService {

  private api = "http://localhost:8080/api/expenses";

  constructor(private http: HttpClient) {}

  getAll(): Observable<ExpenseDto[]> {
    return this.http.get<ExpenseDto[]>(this.api);
  }

  getLookups(): Observable<ExpenseLookups> {
    return this.http.get<ExpenseLookups>(`${this.api}/lookups`);
  }

  create(req: CreateExpenseRequest): Observable<ExpenseDto> {
    return this.http.post<ExpenseDto>(this.api, req);
  }
}
