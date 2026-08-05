import { Injectable } from "@angular/core";
import { HttpClient } from "@angular/common/http";
import { Observable } from "rxjs";

export interface AccountDto {
  id: number;
  accountCode: string;
  accountTitle: string;
  description: string;
  accountNumber: string;
  contactPerson: string;
  phone: string;
  internetBankingUrl: string;
  initialBalanceBdt: number;
  initialBalanceUsd: number;
  totalDeposits: number;
  totalExpenses: number;
  totalTransfersIn: number;
  totalTransfersOut: number;
  currentBalance: number;
  status: string;
  createdAt: string;
  updatedAt: string;
}

export interface CreateAccountRequest {
  accountTitle: string;
  description?: string;
  accountNumber?: string;
  contactPerson?: string;
  phone?: string;
  internetBankingUrl?: string;
  initialBalanceBdt?: number;
  initialBalanceUsd?: number;
}

@Injectable({ providedIn: "root" })
export class AccountService {

  private api = "http://localhost:8080/api/accounts";

  constructor(private http: HttpClient) {}

  getAll(): Observable<AccountDto[]> {
    return this.http.get<AccountDto[]>(this.api);
  }

  getById(id: number): Observable<AccountDto> {
    return this.http.get<AccountDto>(`${this.api}/${id}`);
  }

  create(req: CreateAccountRequest): Observable<AccountDto> {
    return this.http.post<AccountDto>(this.api, req);
  }

  update(id: number, req: Partial<CreateAccountRequest>): Observable<AccountDto> {
    return this.http.put<AccountDto>(`${this.api}/${id}`, req);
  }

  recordInitialBalance(id: number, initialBalanceBdt: number, initialBalanceUsd: number): Observable<AccountDto> {
    return this.http.put<AccountDto>(`${this.api}/${id}/initial-balance`, { initialBalanceBdt, initialBalanceUsd });
  }

  setStatus(id: number, active: boolean): Observable<string> {
    return this.http.put(`${this.api}/${id}/status`, { active }, { responseType: "text" });
  }

  delete(id: number): Observable<string> {
    return this.http.delete(`${this.api}/${id}`, { responseType: "text" });
  }
}
